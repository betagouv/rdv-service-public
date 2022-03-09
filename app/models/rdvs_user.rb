# frozen_string_literal: true

class RdvsUser < ApplicationRecord
  # Relations
  belongs_to :rdv, touch: true, inverse_of: :rdvs_users, counter_cache: :rdv_collectif_users_count
  belongs_to :user

  # Validations
  # Uniqueness validation doesn’t work with nested_attributes, see https://github.com/rails/rails/issues/4568
  # We do have on a DB constraint.
  validates :user_id, uniqueness: { scope: :rdv_id }

  # Hooks
  after_initialize :set_default_notifications_flags
  before_validation :set_default_notifications_flags

  ## -

  def set_default_notifications_flags
    return if rdv&.motif.nil?

    self.send_lifecycle_notifications = rdv.motif.visible_and_notified? if send_lifecycle_notifications.nil?
    self.send_reminder_notification = rdv.motif.visible_and_notified? if send_reminder_notification.nil?
  end
end
