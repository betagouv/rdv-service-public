class RdvEvent < ApplicationRecord
  TYPE_NOTIFICATION_SMS = "notification_sms".freeze
  TYPE_NOTIFICATION_MAIL = "notification_mail".freeze

  validates :event_type, inclusion: { in: [TYPE_NOTIFICATION_SMS, TYPE_NOTIFICATION_MAIL] }

  belongs_to :rdv
end
