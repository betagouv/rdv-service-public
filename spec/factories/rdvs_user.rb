# frozen_string_literal: true

FactoryBot.define do
  factory :rdvs_user do
    user
    rdv
    send_lifecycle_notifications { nil }
    send_reminder_notification { nil }
    status { "unknown" }
    created_by { :agent }
  end
end
