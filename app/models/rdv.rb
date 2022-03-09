# frozen_string_literal: true

class Rdv < ApplicationRecord
  # Mixins
  has_paper_trail(
    only: %w[user_ids agent_ids status starts_at ends_at lieu_id notes location context rdvs_users],
    meta: { virtual_attributes: :virtual_attributes_for_paper_trail }
  )

  include WebhookDeliverable
  include Rdv::AddressConcern
  include IcalHelpers::Ics
  include Payloads::Rdv

  # Attributes
  enum status: { unknown: "unknown", waiting: "waiting", seen: "seen", excused: "excused", revoked: "revoked", noshow: "noshow" }
  NOT_CANCELLED_STATUSES = %w[unknown waiting seen].freeze
  CANCELLED_STATUSES = %w[excused revoked noshow].freeze
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
  has_many :events, class_name: "RdvEvent", dependent: :destroy

  accepts_nested_attributes_for :rdvs_users, allow_destroy: true

  # Through relations
  has_many :agents, through: :agents_rdvs, dependent: :destroy
  has_many :users, through: :rdvs_users, validate: false
  has_many :webhook_endpoints, through: :organisation

  # Delegates
  delegate :home?, :phone?, :public_office?, :reservable_online?, :service_social?, :follow_up?, :service, :collectif?, to: :motif

  # Validations
  validates :starts_at, :ends_at, :agents, presence: true
  validates :rdvs_users, presence: true, unless: :collectif?
  validates :lieu, presence: true, if: :public_office?
  validate :starts_at_is_plausible
  validate :duration_is_plausible
  validates :max_participants_count, numericality: { greater_than: 0, allow_nil: true }

  # Hooks
  after_save :associate_users_with_organisation
  after_commit :update_agents_unknown_past_rdv_count, if: -> { past? }
  after_commit :reload_uuid, on: :create

  # Scopes
  scope :not_cancelled, -> { where(status: NOT_CANCELLED_STATUSES) }
  scope :cancelled, -> { where(status: CANCELLED_STATUSES) }
  scope :past, -> { where("starts_at < ?", Time.zone.now) }
  scope :future, -> { where("starts_at > ?", Time.zone.now) }
  scope :start_after, ->(time) { where("starts_at > ?", time) }
  scope :tomorrow, -> { where(starts_at: DateTime.tomorrow...DateTime.tomorrow + 1.day) }
  scope :day_after_tomorrow, -> { where(starts_at: DateTime.tomorrow + 1.day...DateTime.tomorrow + 2.days) }
  scope :for_today, -> { where(starts_at: Time.zone.now.beginning_of_day...Time.zone.now.end_of_day) }
  scope :user_with_relatives, ->(responsible_id) { joins(:users).includes(:rdvs_users, :users).where(users: { id: [responsible_id, User.find(responsible_id).relatives.pluck(:id)].flatten }) }
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
  scope :visible, -> { joins(:motif).where(motifs: { visibility_type: [Motif::VISIBLE_AND_NOTIFIED, Motif::VISIBLE_AND_NOT_NOTIFIED] }) }

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

  def today?
    Time.zone.today == starts_at.to_date
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

  def cancellable?
    !cancelled? && starts_at > 4.hours.from_now
  end

  def available_to_file_attente?
    !cancelled? && starts_at > 7.days.from_now && !home?
  end

  def creneaux_available(date_range)
    date_range = Lapin::Range.reduce_range_to_delay(motif, date_range) # réduit le range en fonction du délay
    lieu.present? ? SlotBuilder.available_slots(motif, lieu, date_range, OffDays.all_in_date_range(date_range)) : []
  end

  def user_for_home_rdv
    responsibles = users.where.not(responsible_id: [nil])
    [responsibles, users].flatten.select(&:address).first || users.first
  end

  def overlapping_plages_ouvertures
    return [] if starts_at.blank? || ends_at.blank? || lieu.blank? || past? || errors.present?

    @overlapping_plages_ouvertures ||= PlageOuverture.where(agent: agents).where.not(lieu: lieu).overlapping_with_time_slot(to_time_slot)
  end

  def overlapping_plages_ouvertures?
    overlapping_plages_ouvertures.any?
  end

  def to_time_slot
    TimeSlot.new(starts_at, ends_at)
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
    rdvs = rdvs.joins(:lieu).where(lieux: { id: options["lieu_id"] }) if options["lieu_id"].present?
    rdvs = rdvs.joins(:agents).where(agents: { id: options["agent_id"] }) if options["agent_id"].present?
    rdvs = rdvs.joins(:rdvs_users).where(rdvs_users: { user_id: options["user_id"] }) if options["user_id"].present?
    rdvs = rdvs.status(options["status"]) if options["status"].present?
    rdvs = rdvs.where("DATE(starts_at) >= ?", options["start"]) if options["start"].present?
    rdvs = rdvs.where("DATE(starts_at) <= ?", options["end"]) if options["end"].present?
    rdvs
  end

  def participants_with_life_cycle_notification_ids
    rdvs_users.where(send_lifecycle_notifications: true).pluck(:user_id)
  end

  def remaining_seats?
    return true unless max_participants_count

    rdv_collectif_users_count < max_participants_count
  end

  def fully_booked?
    return false unless max_participants_count

    rdv_collectif_users_count == max_participants_count
  end

  def overbooked?
    return true unless max_participants_count

    rdv_collectif_users_count > max_participants_count
  end

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

    errors.add(:duration_in_min, :must_be_positive) if starts_at > ends_at
  end

  def virtual_attributes_for_paper_trail
    {
      user_ids: users.ids,
      agent_ids: agents.ids,
      rdvs_users: rdvs_users.map do |rdvs_user|
        rdvs_user.slice(:user_id, :send_lifecycle_notifications, :send_reminder_notification)
      end
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

  def reload_uuid
    # https://github.com/rails/rails/issues/17605
    self[:uuid] = self.class.where(id: id).pick(:uuid) if attributes.key? "uuid"
  end
end
