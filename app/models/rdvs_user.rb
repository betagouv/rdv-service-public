# frozen_string_literal: true

class RdvsUser < ApplicationRecord
  belongs_to :rdv, touch: true, inverse_of: :rdvs_users
  belongs_to :user

  after_initialize :set_default_notifications_flags
  before_validation :set_default_notifications_flags

  def set_default_notifications_flags
    return if rdv&.motif.nil?

    self.send_lifecycle_notifications = rdv.motif.visible_and_notified? if send_lifecycle_notifications.nil?
    self.send_reminder_notification = rdv.motif.visible_and_notified? if send_reminder_notification.nil?
  end
end
