class Rdv < ApplicationRecord
  # Mixins
  has_paper_trail(
    only: %w[user_ids agent_ids status starts_at ends_at lieu_id notes context participations],
    meta: { virtual_attributes: :virtual_attributes_for_paper_trail }
  )

  include WebhookDeliverable
  include Rdv::AddressConcern
  include Rdv::AuthoredConcern
  include Rdv::Updatable
  include Rdv::UsingWaitingRoom
  include Rdv::HardcodedAttributeNamesConcern
  include IcsPayloads::Rdv
  include Ants::AppointmentSerializerAndListener
  include CreatedByConcern

  # Attributes
  auto_strip_attributes :name
  enum :status, { unknown: "unknown", seen: "seen", excused: "excused", revoked: "revoked", noshow: "noshow" }
  # Commentaire pour les status explications
  # unknown : "A renseigner" ou "A venir" (si le rdv est passé ou pas)
  # seen : Présent au rdv
  # noshow : Lapin
  # excused : Annulé à l'initiative de l'usager
  # revoked : Annulé à l'initiative du service
  MIN_DELAY_FOR_CANCEL = 4.hours
  NOT_CANCELLED_STATUSES = %w[unknown seen noshow].freeze
  CANCELLED_STATUSES = %w[excused revoked].freeze
  COLLECTIVE_RDV_STATUSES = %w[unknown seen revoked].freeze
  RDV_STATUSES_TO_NOTIFY = %w[unknown excused revoked].freeze

  # Relations
  belongs_to :organisation
  belongs_to :motif
  belongs_to :lieu, optional: true
  has_many :file_attentes, dependent: :destroy
  has_many :agents_rdvs, inverse_of: :rdv, dependent: :destroy
  # https://stackoverflow.com/questions/30629680/rails-isnt-running-destroy-callbacks-for-has-many-through-join-model/30629704
  # https://github.com/rails/rails/issues/7618
  has_many :participations, validate: false, inverse_of: :rdv, dependent: :destroy, class_name: "Participation"
  has_many :receipts, dependent: :nullify

  accepts_nested_attributes_for :participations, allow_destroy: true
  accepts_nested_attributes_for :lieu
  ACCEPTED_NESTED_LIEU_ATTRIBUTES = %w[name address latitude longitude].freeze
  def nested_lieu_attributes
    lieu&.attributes&.slice(*ACCEPTED_NESTED_LIEU_ATTRIBUTES)
  end

  # Through relations
  has_many :agents, through: :agents_rdvs, dependent: :destroy
  has_many :users, through: :participations, validate: false
  has_many :webhook_endpoints, through: :organisation
  has_one :territory, through: :organisation

  # Delegates
  delegate :home?, :phone?, :public_office?, :visio?, :bookable_by_everyone?,
           :bookable_by_everyone_or_bookable_by_invited_users?, :service_social?, :follow_up?, :service, :collectif?, :collectif, :individuel?, :requires_ants_predemande_number?, to: :motif

  # Validations
  validates :starts_at, :ends_at, :agents, presence: true
  validate :lieu_is_not_disabled_if_needed
  validates :starts_at, realistic_date: true
  validate :duration_is_plausible
  validates :max_participants_count, numericality: { greater_than: 0, allow_nil: true }

  validates :participations, presence: true, unless: :collectif?
  validates :status, inclusion: { in: COLLECTIVE_RDV_STATUSES }, if: :collectif?

  # Hooks
  after_save :associate_users_with_organisation
  after_commit :update_agents_unknown_past_rdv_count, if: -> { past? }
  before_validation { self.uuid ||= SecureRandom.uuid }
  before_create :set_created_by_for_participations
  # voir Outlook::EventSerializerAndListener pour d'autres callbacks
  # voir Ants::AppointmentSerializerAndListener pour d'autres callbacks

  # Scopes
  scope :not_cancelled, -> { where(status: NOT_CANCELLED_STATUSES) }
  scope :past, -> { where("starts_at < ?", Time.zone.now) }
  scope :future, -> { where("starts_at > ?", Time.zone.now) }
  scope :starts_after, ->(time) { where("starts_at >= ?", time) }
  scope :starts_before, ->(time) { where("starts_at <= ?", time) }
  scope :on_day, ->(day) { where(starts_at: day.all_day) }
  scope :day_after_tomorrow, -> { on_day(Time.zone.tomorrow + 1.day) }
  scope :for_today, -> { on_day(Time.zone.today) }
  scope :user_with_relatives, ->(responsible_id) { joins(:users).includes(:participations, :users).where(users: { id: [responsible_id, User.find(responsible_id).relatives.pluck(:id)].flatten }) }
  scope :with_user, ->(user) { with_user_id(user.id) }
  scope :with_user_id, ->(user_id) { joins(:users).where(participations: { user_id: user_id }) }
  scope :status, lambda { |status|
    case status.to_s
    when "unknown_past"
      past.where(status: "unknown")
    when "unknown_future"
      future.where(status: "unknown")
    else
      where(status: status)
    end
  }
  scope :visible, -> { joins(:motif).merge(Motif.visible) }
  scope :collectif, -> { joins(:motif).merge(Motif.collectif) }
  scope :collectif_and_available_for_reservation, -> { collectif.with_remaining_seats.future.not_revoked }
  scope :bookable_by_everyone, -> { joins(:motif).merge(Motif.bookable_by_everyone) }
  scope :bookable_by_everyone_or_bookable_by_invited_users, -> { joins(:motif).merge(Motif.bookable_by_everyone_or_bookable_by_invited_users) }
  scope :bookable_by_everyone_or_agents_and_prescripteurs_or_invited_users, -> { joins(:motif).merge(Motif.bookable_by_everyone_or_agents_and_prescripteurs_or_invited_users) }
  scope :with_remaining_seats, -> { where("users_count < max_participants_count OR max_participants_count IS NULL") }
  scope :for_domain, lambda { |domain|
    if domain == Domain::RDV_AIDE_NUMERIQUE
      joins(:organisation).where(organisations: { verticale: :rdv_aide_numerique })
    else
      joins(:organisation).where.not(organisations: { verticale: :rdv_aide_numerique })
    end
  }
  scope :requires_ants_predemande_number, -> { joins(:motif).merge(Motif.requires_ants_predemande_number) }

  # Delegations
  delegate :domain, to: :organisation
  delegate :name, to: :motif, prefix: true

  ## -

  def self.ongoing(time_margin: 0.minutes)
    where("starts_at <= ?", Time.zone.now + time_margin)
      .where("ends_at >= ?", Time.zone.now - time_margin)
  end

  def past?
    ends_at < Time.zone.now
  end

  def in_the_past?
    starts_at <= Time.zone.now
  end

  def in_the_future?
    starts_at >= Time.zone.now
  end

  def temporal_status
    Rdv.temporal_status(status, starts_at)
  end

  def starts_at=(value)
    super
    set_ends_at
  end

  def duration_in_min=(value)
    @duration_in_min = value
    set_ends_at
  end

  def duration_in_min
    return @duration_in_min&.to_i if starts_at.nil? || ends_at.nil?

    ActiveSupport::Duration.build(ends_at - starts_at).in_minutes.to_i
  end

  def set_ends_at
    return if starts_at.nil? || @duration_in_min.nil?

    self.ends_at = starts_at + @duration_in_min.to_i.minutes
  end

  # class method: helps convert the "unknown" status to a temporal variant "unknown_future" or "unknown_past"
  def self.temporal_status(status, starts_at)
    if status == "unknown"
      rdv_date = starts_at.to_date
      if rdv_date > Time.zone.today # future
        "unknown_future"
      elsif rdv_date == Time.zone.today # today
        "unknown_today"
      else # past
        "unknown_past"
      end
    else
      status
    end
  end

  def cancelled?
    status.in? CANCELLED_STATUSES
  end

  def not_cancelled?
    status.in? NOT_CANCELLED_STATUSES
  end

  def cancellable_by_user?
    !cancelled? && !collectif? && motif.rdvs_cancellable_by_user? && starts_at > MIN_DELAY_FOR_CANCEL.from_now
  end

  def editable_by_user?
    !cancelled? && !collectif? && motif.rdvs_editable_by_user? && starts_at > 2.days.from_now &&
      motif.bookable_by_everyone_or_bookable_by_invited_users? && !created_by_agent?
  end

  def available_to_file_attente?
    motif.bookable_by_everyone? &&
      motif.individuel? &&
      !cancelled? &&
      starts_at > 7.days.from_now &&
      !home?
  end

  def creneaux_available(date_range)
    date_range = CreneauxSearch::Range.reduce_range_to_delay(motif, date_range) # réduit le range en fonction du délay
    return [] if date_range.blank?

    CreneauxSearch::Calculator.available_slots(motif, lieu, date_range)
  end

  def user_for_home_rdv
    responsibles = users.loaded? ? users.select(&:responsible_id) : users.where.not(responsible_id: [nil])
    [responsibles, users].flatten.select(&:address).first || users.first
  end

  # Ces plages d'ouvertures sont utilisé pour afficher des infos
  # s'il y a un chevauchement avec le RDV.
  #
  # Il y a une vérification de scope dans l'appelant (pourquoi ?)
  # et utilisation du nom et du lieu
  #
  def overlapping_plages_ouvertures
    return [] if starts_at.blank? || ends_at.blank? || lieu.blank? || past? || errors.present?

    @overlapping_plages_ouvertures ||= PlageOuverture
      .where(agent: agent_ids)
      .where.not(lieu: lieu)
      .overlapping_range(starts_at..ends_at)
  end

  def overlapping_plages_ouvertures?
    overlapping_plages_ouvertures.any?
  end

  def overlapping_absences
    return [] if starts_at.blank? || ends_at.blank? || past? || errors.present?

    @overlapping_absences ||= Absence.where(agent: agent_ids).overlapping_range(starts_at..ends_at)
  end

  def overlapping_absences?
    overlapping_absences.any?
  end

  def phone_number
    return lieu.phone_number if lieu&.phone_number.present?
    return organisation.phone_number if organisation&.phone_number.present?

    ""
  end

  def phone_number_formatted
    return lieu.phone_number_formatted if lieu&.phone_number_formatted.present?
    return organisation.phone_number if organisation&.phone_number.present?

    ""
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def self.search_for(organisations, options)
    rdvs = joins(:organisation).where(organisation: organisations)
    options = options.with_indifferent_access.select { |_, value| Array(value).compact_blank.present? }

    rdvs = rdvs.joins(:lieu).where(lieux: { id: options[:lieu_ids] }) if options[:lieu_ids]
    rdvs = rdvs.joins(:motif).where(motifs: { id: options[:motif_ids] }) if options[:motif_ids]
    rdvs = rdvs.joins(:agents).where(agents: { id: options[:agent_id] }) if options[:agent_id]
    rdvs = rdvs.with_user_id(options[:user_id]) if options[:user_id]
    rdvs = rdvs.status(options[:status]) if options[:status]
    rdvs = rdvs.where("DATE(starts_at) >= ?", options[:start]) if options[:start]
    rdvs = rdvs.where("DATE(ends_at) <= ?", options[:end]) if options[:end]

    rdvs
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def reschedule_max_date
    Time.zone.now + motif.max_public_booking_delay
  end

  def remaining_seats?
    return true unless max_participants_count

    users_count < max_participants_count
  end

  def fully_booked?
    return false unless max_participants_count

    users_count == max_participants_count
  end

  def overbooked?
    return false unless max_participants_count

    users_count > max_participants_count
  end

  # FIXME: we should either rename the column, or avoid the ambiguity in rdv_payload
  def title
    name
  end

  def synthesized_receipts_result
    results = receipts.pluck(:result).uniq

    return if results.empty?

    results.exclude?("failure") ? "processed" : "failure"
  end

  # On aimerait que le helper rdv_title_in_agenda renvoie la bonne chose directement.
  # Malheureusement il renvoie un titre moins clair dans le cas d'un rdv individuel.
  # Il nécessiterait peut être une refacto et donc la suppresion de cette méthode
  def object
    collectif? ? ApplicationController.helpers.rdv_title_in_agenda(self) : motif_name
  end

  def event_description_for(agent)
    link = Rails.application.routes.url_helpers
      .admin_organisation_rdv_url(organisation, id, host: agent.domain.host_name)

    "plus d'infos dans #{agent.domain_name}: #{link}"
  end

  def update_users_count
    users_count = participations.not_cancelled.count
    update_column(:users_count, users_count)
  end

  def update_rdv_status_from_participation
    return seen! if participations.any?(&:seen?)

    if collectif?
      update_collective_rdv_status
    else
      update_individual_rdv_status
    end
  end

  def seen!
    update!(cancelled_at: nil, status: "seen")
  end

  def unknown!
    update!(cancelled_at: nil, status: "unknown")
  end

  def excused!
    update!(cancelled_at: Time.zone.now, status: "excused")
  end

  def noshow!
    update!(cancelled_at: Time.zone.now, status: "noshow")
  end

  def revoked!
    update!(cancelled_at: Time.zone.now, status: "revoked")
  end

  def visio_url
    return nil unless motif.visio?

    # Jitsi n'autorise pas les - et _ dans les liens de visio
    "https://webconf.numerique.gouv.fr/RdvServicePublic#{uuid}".gsub(/[-_]/, "")
  end

  private

  def update_collective_rdv_status
    revoked! if participations.none?(&:unknown?) && in_the_past?
  end

  def update_individual_rdv_status
    if participations.all?(&:excused?)
      excused!
    elsif participations.all?(&:revoked?)
      revoked!
    elsif participations.all?(&:noshow?)
      noshow!
    else
      unknown!
    end
  end

  def duration_is_plausible
    return if starts_at.nil? || ends_at.nil?

    errors.add(:duration_in_min, :must_be_positive) if starts_at >= ends_at
  end

  def lieu_is_not_disabled_if_needed
    return unless motif.public_office?

    errors.add(:lieu, :blank) if lieu.nil?
    errors.add(:lieu, :must_not_be_disabled) if lieu&.disabled?
  end

  def virtual_attributes_for_paper_trail
    {
      user_ids: users.ids,
      agent_ids: agents.ids,
      participations: participations.map do |participation|
        participation.slice(
          :user_id,
          :send_lifecycle_notifications,
          :send_reminder_notification,
          :status,
          :created_by_type,
          :created_by_id
        )
      end,
    }
  end

  def associate_users_with_organisation
    users.each do |u|
      u.add_organisation(organisation)
    end
  end

  def update_agents_unknown_past_rdv_count
    agents.each(&:update_unknown_past_rdv_count!)
  end

  def set_created_by_for_participations
    participations.each { |participation| participation.created_by = created_by }
  end
end
