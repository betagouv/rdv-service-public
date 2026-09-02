FactoryBot.define do
  factory :external_calendar_sync_executions_log do
    external_calendar_sync_execution { association(:external_calendar_sync_execution) }
    message { "message de test" }
    emitted_at { Time.zone.now }
  end
end
