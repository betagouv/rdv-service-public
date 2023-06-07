# frozen_string_literal: true

class Rdv < ApplicationRecord
  # Mixins
  has_paper_trail(
    only: %w[user_ids agent_ids status starts_at ends_at lieu_id notes context rdvs_users],
    meta: { virtual_attributes: :virtual_attributes_for_paper_trail }
  )

  include WebhookDeliverable
  include Rdv::AddressConcern
  include Rdv::AuthoredConcern
  include Rdv::Updatable
  include Rdv::UsingWaitingRoom
  include IcalHelpers::Ics
  include Payloads::Rdv

  # Attributes
  auto_strip_attributes :name
  enum status: { unknown: "unknown", seen: "seen", excused: "excused", revoked: "revoked", noshow: "noshow" }
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
  enum created_by: { agent: 0, user: 1, file_attente: 2, prescripteur: 3 }, _prefix: :created_by

  # Relations
  belongs_to :organisation
  belongs_to :motif
  belongs_to :lieu, optional: true
  has_many :file_attentes, dependent: :destroy
  has_many :agents_rdvs, inverse_of: :rdv, dependent: :destroy
  # https://stackoverflow.com/questions/30629680/rails-isnt-running-destroy-callbacks-for-has-many-through-join-model/30629704
  # https://github.com/rails/rails/issues/7618
  has_many :rdvs_users, validate: false, inverse_of: :rdv, dependent: :destroy, class_name: "RdvsUser"
  has_many :receipts, dependent: :destroy

  accepts_nested_attributes_for :rdvs_users, allow_destroy: true
  accepts_nested_attributes_for :lieu
  ACCEPTED_NESTED_LIEU_ATTRIBUTES = %w[name address latitude longitude].freeze
  def nested_lieu_attributes
    lieu&.attributes&.slice(*ACCEPTED_NESTED_LIEU_ATTRIBUTES)
  end

  # Through relations
  has_many :agents, through: :agents_rdvs, dependent: :destroy
  has_many :users, through: :rdvs_users, validate: false
  has_many :webhook_endpoints, through: :organisation
  has_one :territory, through: :organisation

  # Delegates
  delegate :home?, :phone?, :public_office?, :bookable_publicly?, :service_social?, :follow_up?, :service, :collectif?, :collectif, :individuel?, to: :motif

  alias_attribute :soft_deleted?, :deleted_at?

  # Validations
  validates :starts_at, :ends_at, :agents, presence: true
  validate :lieu_is_not_disabled_if_needed
  validate :starts_at_is_plausible
  validate :duration_is_plausible
  validates :max_participants_count, numericality: { greater_than: 0, allow_nil: true }

  validates :rdvs_users, presence: true, unless: :collectif?
  validates :status, inclusion: { in: COLLECTIVE_RDV_STATUSES }, if: :collectif?

  # Hooks
  after_save :associate_users_with_organisation
  after_commit :update_agents_unknown_past_rdv_count, if: -> { past? }
  before_validation { self.uuid ||= SecureRandom.uuid }
  before_create :set_created_by_for_participations
  # voir Outlook::EventSerializerAndListener pour d'autres callbacks

  # Scopes
  default_scope { where(deleted_at: nil) }
  scope :not_cancelled, -> { where(status: NOT_CANCELLED_STATUSES) }
  scope :past, -> { where("starts_at < ?", Time.zone.now) }
  scope :future, -> { where("starts_at > ?", Time.zone.now) }
  scope :start_after, ->(time) { where("starts_at > ?", time) }
  scope :on_day, ->(day) { where(starts_at: day.all_day) }
  scope :day_after_tomorrow, -> { on_day(Time.zone.tomorrow + 1.day) }
  scope :for_today, -> { on_day(Time.zone.today) }
  scope :user_with_relatives, ->(responsible_id) { joins(:users).includes(:rdvs_users, :users).where(users: { id: [responsible_id, User.find(responsible_id).relatives.pluck(:id)].flatten }) }
  scope :with_user, ->(user) { with_user_id(user.id) }
  scope :with_user_id, ->(user_id) { joins(:users).where(rdvs_users: { user_id: user_id }) }
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
  scope :bookable_publicly, -> { joins(:motif).merge(Motif.bookable_publicly) }
  scope :with_remaining_seats, -> { where("users_count < max_participants_count OR max_participants_count IS NULL") }
  scope :for_domain, lambda { |domain|
    if domain == Domain::RDV_AIDE_NUMERIQUE
      joins(:organisation).where(organisations: { verticale: :rdv_aide_numerique })
    else
      joins(:organisation).where.not(organisations: { verticale: :rdv_aide_numerique })
    end
  }
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
      motif.bookable_publicly && !created_by_agent?
  end

  def available_to_file_attente?
    motif.bookable_publicly? &&
      motif.individuel? &&
      !cancelled? &&
      starts_at > 7.days.from_now &&
      !home?
  end

  def creneaux_available(date_range)
    date_range = Lapin::Range.reduce_range_to_delay(motif, date_range) # réduit le range en fonction du délay
    return [] if date_range.blank?

    SlotBuilder.available_slots(motif, lieu, date_range)
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

  def self.search_for(organisations, options)
    organisation_ids = [organisations.id] if organisations.is_a?(Organisation)
    organisation_ids ||= organisations.ids
    rdvs = joins(:organisation).where(organisations: { id: organisation_ids })
    options.each do |key, value|
      next if value.blank?

      rdvs = send("search_for_#{key}", rdvs, value) if respond_to?("search_for_#{key}")
    end
    rdvs
  end

  def self.search_for_lieu_id(rdvs, lieu_id)
    rdvs.joins(:lieu).where(lieux: { id: lieu_id })
  end

  def self.search_for_motif_id(rdvs, motif_id)
    rdvs.joins(:motif).where(motifs: { id: motif_id })
  end

  def self.search_for_agent_id(rdvs, agent_id)
    rdvs.joins(:agents).where(agents: { id: agent_id })
  end

  def self.search_for_user_id(rdvs, user_id)
    rdvs.with_user_id(user_id)
  end

  def self.search_for_status(rdvs, status)
    rdvs.status(status)
  end

  def self.search_for_start(rdvs, start_at)
    rdvs.where("DATE(starts_at) >= ?", start_at)
  end

  def self.search_for_end(rdvs, end_at)
    rdvs.where("DATE(starts_at) <= ?", end_at)
  end

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

  def soft_delete
    # disable the :updated webhook because we want to manually trigger a :destroyed webhook
    self.skip_webhooks = true
    return false unless update(deleted_at: Time.zone.now)

    generate_payload_and_send_webhook_for_destroy
    true
  end

  def update_users_count
    users_count = rdvs_users.not_cancelled.count
    update_column(:users_count, users_count)
  end

  def update_rdv_status_from_participation
    if rdvs_users.any?(&:seen?)
      update!(status: "seen")
      return
    end

    if rdvs_users.none?(&:seen?) && rdvs_users.none?(&:unknown?)
      update_status_to_revoked
    end
  end

  def update_status_to_revoked
    # Only rdv in the past ca be automatically set to revoked
    return if in_the_future?

    self.cancelled_at = Time.zone.now
    update!(status: "revoked")
  end

  private

  def starts_at_is_plausible
    return unless will_save_change_to_attribute?("starts_at")
    return unless starts_at > Time.zone.now + 2.years

    errors.add(:starts_at, :must_be_within_two_years)
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
      rdvs_users: rdvs_users.map do |rdvs_user|
        rdvs_user.slice(
          :user_id,
          :send_lifecycle_notifications,
          :send_reminder_notification,
          :status,
          :created_by
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
    rdvs_users.each { |rdvs_user| rdvs_user.created_by = created_by }
  end
end
