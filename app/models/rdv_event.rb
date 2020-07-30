class RdvEvent < ApplicationRecord
  TYPE_NOTIFICATION_SMS = "notification_sms".freeze
  TYPE_NOTIFICATION_MAIL = "notification_mail".freeze

  validates :event_type, inclusion: { in: [TYPE_NOTIFICATION_SMS, TYPE_NOTIFICATION_MAIL] }

  belongs_to :rdv

  def self.date_stats(date = Date.today)
    [TYPE_NOTIFICATION_SMS, TYPE_NOTIFICATION_MAIL].map do |event_type|
      events_by_name = RdvEvent
        .where(event_type: event_type)
        .where("date(created_at) = ?", date)
        .group(:event_name)
        .count
      [event_type, events_by_name.merge("total" => events_by_name.values.sum)]
    end.to_h
  end
end
