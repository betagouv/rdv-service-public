# frozen_string_literal: true

class RdvEvent < ApplicationRecord
  # Attributes
  # TODO: make it an enum
  TYPE_NOTIFICATION_SMS = "notification_sms"
  TYPE_NOTIFICATION_MAIL = "notification_mail"

  # Relations
  belongs_to :rdv

  # Validations
  validates :event_type, inclusion: { in: [TYPE_NOTIFICATION_SMS, TYPE_NOTIFICATION_MAIL] }

  ## -

  def self.date_stats(date = Time.zone.today)
    [TYPE_NOTIFICATION_SMS, TYPE_NOTIFICATION_MAIL].to_h do |event_type|
      events_by_name = RdvEvent
        .where(event_type: event_type)
        .where("date(created_at) = ?", date)
        .group(:event_name)
        .count
      [event_type, events_by_name.merge("total" => events_by_name.values.sum)]
    end
  end
end
