# frozen_string_literal: true

class RdvsUser < ApplicationRecord
  devise :invitable
  # Attributes
  enum status: { unknown: "unknown", waiting: "waiting", seen: "seen", excused: "excused", revoked: "revoked", noshow: "noshow" }

  # Relations
  belongs_to :rdv, touch: true, inverse_of: :rdvs_users, counter_cache: :users_count
  belongs_to :user

  # Validations
  # Uniqueness validation doesn’t work with nested_attributes, see https://github.com/rails/rails/issues/4568
  # We do have on a DB constraint.
  validates :user_id, uniqueness: { scope: :rdv_id }

  # Hooks
  after_initialize :set_default_notifications_flags
  before_validation :set_default_notifications_flags

  # Temporary Hooks for Participation feature
  after_initialize :set_status
  ## -
  # TODORDV-C Hook on change status : notifiers

  def set_status
    # if rdv revoked,
    # revoked toutes les participations (check notifs)
    
    # TODORDV-C rdv.status behavior on participations
    # return if rdv&.status.nil?

    # self.status = rdv.status
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
end
