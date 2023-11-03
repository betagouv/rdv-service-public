FactoryBot.define do
  factory :participation do
    user
    rdv
    send_lifecycle_notifications { nil }
    send_reminder_notification { nil }
    status { "unknown" }
    created_by { :agent }
  end
end
