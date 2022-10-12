# frozen_string_literal: true

class RdvsUser < ApplicationRecord
  # Mixins
  devise :invitable

  include RdvsUser::StatusChangeable

  # Attributes
  enum status: { unknown: "unknown", waiting: "waiting", seen: "seen", excused: "excused", revoked: "revoked", noshow: "noshow" }
  NOT_CANCELLED_STATUSES = %w[unknown waiting seen noshow].freeze
  CANCELLED_STATUSES = %w[excused revoked].freeze

  # Relations
  belongs_to :rdv, touch: true, inverse_of: :rdvs_users, counter_cache: :users_count
  belongs_to :user

  # Validations
  # Uniqueness validation doesn’t work with nested_attributes, see https://github.com/rails/rails/issues/4568
  # We do have on a DB constraint.
  validates :user_id, uniqueness: { scope: :rdv_id }
  validate :status_cannot_be_changed_if_rdv_status_is_revoked, on: :update

  # Hooks
  after_initialize :set_default_notifications_flags
  before_validation :set_default_notifications_flags
  before_create :set_status_from_rdv

  # Scopes
  scope :order_by_user_last_name, -> { includes(:user).order("users.last_name ASC") }
  scope :not_cancelled, -> { where(status: NOT_CANCELLED_STATUSES) }
  # For scoping notifications exceptions, todo get a better name, this override rails named method....
  scope :not_excused, -> { where.not(status: "excused") }

  def set_status_from_rdv
    return if rdv&.status.nil?

    self.status = rdv.status
  end

  def temporal_status
    RdvsUser.temporal_status(status, rdv.starts_at)
  end

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

  def set_default_notifications_flags
    return if rdv&.motif.nil?

    self.send_lifecycle_notifications = rdv.motif.visible_and_notified? if send_lifecycle_notifications.nil?
    self.send_reminder_notification = rdv.motif.visible_and_notified? if send_reminder_notification.nil?
  end

  def new_raw_invitation_token
    invite! { |rdv_u| rdv_u.skip_invitation = true }
    raw_invitation_token
  end

  private

  def status_cannot_be_changed_if_rdv_status_is_revoked
    if status_changed? && status != "revoked" && rdv.status == "revoked"
      errors.add(:status, :status_cannot_be_changed_if_rdv_status_is_revoked)
    end
  end
end
