# frozen_string_literal: true

class RdvsUser < ApplicationRecord
  # Mixins
  devise :invitable

  include RdvsUser::StatusChangeable
  include RdvsUser::Creatable

  # Attributes
  enum status: { unknown: "unknown", seen: "seen", excused: "excused", revoked: "revoked", noshow: "noshow" }
  enum created_by: { agent: "agent", user: "user", prescripteur: "prescripteur" }, _prefix: :created_by
  NOT_CANCELLED_STATUSES = %w[unknown seen noshow].freeze
  CANCELLED_STATUSES = %w[excused revoked].freeze

  # Relations
  belongs_to :rdv, touch: true, inverse_of: :rdvs_users, optional: true
  belongs_to :user, inverse_of: :rdvs_users, optional: true
  has_one :prescripteur, dependent: :destroy

  # Delegates
  delegate :full_name, to: :user

  # Validations
  # Uniqueness validation doesn’t work with nested_attributes, see https://github.com/rails/rails/issues/4568
  # We do have on a DB constraint.
  validates :user_id, uniqueness: { scope: :rdv_id }

  # Hooks
  after_initialize :set_default_notifications_flags
  before_validation :set_default_notifications_flags
  before_create :set_status_from_rdv
  after_save :update_counter_cache
  after_destroy :update_counter_cache
  # voir Outlook::EventSerializerAndListener pour d'autres callbacks

  # Scopes
  scope :order_by_user_last_name, -> { includes(:user).order("users.last_name ASC") }
  scope :not_cancelled, -> { where(status: NOT_CANCELLED_STATUSES) }
  scope :past, -> { where("rdvs.starts_at < ?", Time.zone.now) }
  scope :future, -> { where("rdvs.starts_at > ?", Time.zone.now) }
  scope :status, lambda { |status|
    case status.to_s
    when "unknown_past"
      past.where(status: %w[unknown])
    when "unknown_future"
      future.where(status: %w[unknown])
    else
      where(status: status)
    end
  }

  def update_counter_cache
    rdv.update_users_count
  end

  def set_status_from_rdv
    return if rdv&.status.nil? || rdv.collectif?

    self.status = rdv.status
  end

  def temporal_status
    if status == "unknown"
      rdv_date = rdv.starts_at.to_date
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

  def not_cancelled?
    status.in? NOT_CANCELLED_STATUSES
  end

  def cancelled?
    status.in? CANCELLED_STATUSES
  end

  def cancellable_by_user?
    !cancelled? && rdv.collectif? && !rdv.cancelled? && rdv.motif.rdvs_cancellable_by_user? && rdv.starts_at > Rdv::MIN_DELAY_FOR_CANCEL.from_now
  end

  def set_default_notifications_flags
    return if rdv&.motif.nil?

    self.send_lifecycle_notifications = rdv.motif.visible_and_notified? if send_lifecycle_notifications.nil?
    self.send_reminder_notification = rdv.motif.visible_and_notified? if send_reminder_notification.nil?
  end

  def new_raw_invitation_token
    invite! { |rdv_u| rdv_u.skip_invitation = true }
    raw_invitation_token
  end
end
