# frozen_string_literal: true

class Rdv < ApplicationRecord
  include WebhookDeliverable
  include Rdv::AddressConcern
  include IcalHelpers::Ics
  include Payloads::Rdv

  has_paper_trail(
    meta: { virtual_attributes: :virtual_attributes_for_paper_trail }
  )
  belongs_to :organisation
  belongs_to :motif
  belongs_to :lieu, optional: true
  has_many :file_attentes, dependent: :destroy
  has_many :agents_rdvs, inverse_of: :rdv, dependent: :destroy
  has_many :agents, through: :agents_rdvs
  has_many :rdvs_users, validate: false, inverse_of: :rdv, dependent: :destroy
  has_many :users, through: :rdvs_users, validate: false
  has_many :events, class_name: "RdvEvent", dependent: :destroy

  has_many :webhook_endpoints, through: :organisation

  enum status: { unknown: "unknown", waiting: "waiting", seen: "seen", excused: "excused", revoked: "revoked", noshow: "noshow" }
  NOT_CANCELLED_STATUSES = %w[unknown waiting seen].freeze
  CANCELLED_STATUSES = %w[excused revoked noshow].freeze
  enum created_by: { agent: 0, user: 1, file_attente: 2 }, _prefix: :created_by

  delegate :home?, :phone?, :public_office?, :reservable_online?, :service_social?, :follow_up?, :service, to: :motif

  validates :users, :organisation, :motif, :starts_at, :ends_at, :agents, presence: true
  validates :lieu, presence: true, if: :public_office?
  validate :starts_at_is_plausible
  validate :duration_is_plausible

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
  scope :with_agent, ->(agent) { joins(:agents).where(agents: { id: agent.id }) }
  scope :with_agent_among, ->(agents) { agents.map { with_agent(_1) }.reduce(:or) }
  scope :with_user, ->(user) { joins(:rdvs_users).where(rdvs_users: { user_id: user.id }) }
  scope :with_user_in, ->(users) { joins(:rdvs_users).where(rdvs_users: { user_id: users.pluck(:id) }).distinct }
  scope :with_lieu, ->(lieu) { joins(:lieu).where(lieux: { id: lieu.id }) }
  scope :visible, -> { joins(:motif).where(motifs: { visibility_type: [Motif::VISIBLE_AND_NOTIFIED, Motif::VISIBLE_AND_NOT_NOTIFIED] }) }

  before_save :update_unknow_past_rdv_count, if: -> { (status_changed? || new_record?) && past? }
  after_save :associate_users_with_organisation
  after_commit :reload_uuid, on: :create

  def self.ongoing(time_margin: 0.minutes)
    where("starts_at <= ?", Time.zone.now + time_margin)
      .where("ends_at >= ?", Time.zone.now - time_margin)
  end

  def past?
    ends_at < Time.zone.now
  end

  def in_the_future?
    starts_at > Time.zone.now
  end

  def in_the_past?
    starts_at <= Time.zone.now
  end

  def in_next_hour?
    starts_at <= Time.zone.now + 1.hour
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

    ((ends_at - starts_at) / 60).to_i # TODO: use (ends_at - starts_at).in_minutes once we use Rails 6.1
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
    lieu.present? ? CreneauxBuilderService.perform_with(motif.name, lieu, date_range) : []
  end

  def user_for_home_rdv
    responsibles = users.where.not(responsible_id: [nil])
    [responsibles, users].flatten.select(&:address).first || users.first
  end

  def overlapping_plages_ouvertures
    return [] if starts_at.blank? || ends_at.blank? || lieu.blank? || past? || !valid?

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

  private

  def starts_at_is_plausible
    return unless will_save_change_to_attribute?("starts_at")

    if starts_at < Time.zone.now - 2.days
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
    { user_ids: users&.pluck(:id), agent_ids: agents&.pluck(:id) }
  end

  def associate_users_with_organisation
    users.each do |u|
      u.add_organisation(organisation)
    end
  end

  def update_unknow_past_rdv_count
    updater = unknown? ? 1 : -1
    agents.each do |agent|
      agent.update(unknow_past_rdv_count: agent.unknow_past_rdv_count + updater)
    end
  end

  def reload_uuid
    # https://github.com/rails/rails/issues/17605
    self[:uuid] = self.class.where(id: id).pick(:uuid) if attributes.key? "uuid"
  end
end
