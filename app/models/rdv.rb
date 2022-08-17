# frozen_string_literal: true

class Rdv < ApplicationRecord
  # Mixins
  has_paper_trail(
    only: %w[user_ids agent_ids status starts_at ends_at lieu_id notes context rdvs_users],
    meta: { virtual_attributes: :virtual_attributes_for_paper_trail }
  )

  include WebhookDeliverable
  include Rdv::AddressConcern
  include IcalHelpers::Ics
  include Payloads::Rdv

  # Attributes
  enum status: { unknown: "unknown", waiting: "waiting", seen: "seen", excused: "excused", revoked: "revoked", noshow: "noshow" }
  NOT_CANCELLED_STATUSES = %w[unknown waiting seen noshow].freeze
  CANCELLED_STATUSES = %w[excused revoked].freeze
  enum created_by: { agent: 0, user: 1, file_attente: 2 }, _prefix: :created_by

  # Relations
  belongs_to :organisation
  belongs_to :motif
  belongs_to :lieu, optional: true
  has_many :file_attentes, dependent: :destroy
  has_many :agents_rdvs, inverse_of: :rdv, dependent: :destroy
  # https://stackoverflow.com/questions/30629680/rails-isnt-running-destroy-callbacks-for-has-many-through-join-model/30629704
  # https://github.com/rails/rails/issues/7618
  has_many :rdvs_users, validate: false, inverse_of: :rdv, dependent: :destroy
  before_destroy :cant_destroy_if_receipts_exist # must be declared before has_many :receipts
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
  delegate :home?, :phone?, :public_office?, :reservable_online?, :service_social?, :follow_up?, :service, :collectif?, :collectif, :individuel?, to: :motif

  # Validations
  validates :starts_at, :ends_at, :agents, presence: true
  validates :rdvs_users, presence: true, unless: :collectif?
  validate :lieu_is_not_disabled_if_needed
  validate :starts_at_is_plausible
  validate :duration_is_plausible
  validates :max_participants_count, numericality: { greater_than: 0, allow_nil: true }

  # Hooks
  after_save :associate_users_with_organisation
  after_commit :update_agents_unknown_past_rdv_count, if: -> { past? }
  before_validation { self.uuid ||= SecureRandom.uuid }

  # Scopes
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
      past.where(status: %w[unknown waiting])
    when "unknown_future"
      future.where(status: %w[unknown waiting])
    else
      where(status: status)
    end
  }
  scope :visible, -> { joins(:motif).merge(Motif.visible) }
  scope :collectif, -> { joins(:motif).merge(Motif.collectif) }
  scope :with_remaining_seats, -> { where("users_count < max_participants_count OR max_participants_count IS NULL") }
  scope :for_domain, lambda { |domain|
    if domain == Domain::RDV_INCLUSION_NUMERIQUE
      joins(motif: :service).where(service: { name: Service::CONSEILLER_NUMERIQUE })
    else
      # TODO: #rdv-inclusion-numerique-v1 afficher uniquement les rdv du médico-social
      all
    end
  }

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

  def cancellable_by_user?
    !cancelled? && !collectif? && motif.rdvs_cancellable_by_user? && starts_at > 4.hours.from_now
  end

  def editable_by_user?
    !cancelled? && !collectif? && motif.rdvs_editable_by_user? && starts_at > 2.days.from_now &&
      motif.reservable_online && !created_by_agent?
  end

  def available_to_file_attente?
    motif.reservable_online? && !cancelled? && starts_at > 7.days.from_now && !home?
  end

  def creneaux_available(date_range)
    date_range = Lapin::Range.reduce_range_to_delay(motif, date_range) # réduit le range en fonction du délay
    lieu.present? ? SlotBuilder.available_slots(motif, lieu, date_range, OffDays.all_in_date_range(date_range)) : []
  end

  def user_for_home_rdv
    responsibles = users.where.not(responsible_id: [nil])
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

  def self.search_for(agent, organisation, options)
    rdvs = Rdv.where(organisation: organisation)
    unless agent.role_in_organisation(organisation).can_access_others_planning?
      rdvs = rdvs.joins(:motif).where(motifs: { service: agent.service })
    end
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
    Time.zone.now + motif.max_booking_delay
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

  delegate :domain, to: :service

  private

  def starts_at_is_plausible
    return unless will_save_change_to_attribute?("starts_at")

    if starts_at < 2.days.ago
      errors.add(:starts_at, :must_be_future)
    elsif starts_at > Time.zone.now + 2.years
      errors.add(:starts_at, :must_be_within_two_years)
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
      rdvs_users: rdvs_users.map do |rdvs_user|
        rdvs_user.slice(:user_id, :send_lifecycle_notifications, :send_reminder_notification)
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

  def cant_destroy_if_receipts_exist
    # This is similar to using :restrict_with_errors on the has_many :receipts relation, but we want a custom error
    return if receipts.empty?

    errors.add(:base, :cant_destroy_if_receipts_exist)
    throw :abort
  end
end
