FactoryBot.define do
  factory :external_calendar_sync_execution do
    agent { association(:agent) }
    calendar_url { "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id/" }
    started_at { Time.zone.now }
    ended_at { started_at + 1.second if started_at }

    trait :with_logs do
      after(:create) do |external_calendar_sync_execution, _|
        create(:external_calendar_sync_execution_log,
               external_calendar_sync_execution:,
               message: "Un premier truc s'est produit",
               emitted_at: external_calendar_sync_execution.started_at + 0.1.seconds)
        create(:external_calendar_sync_execution_log,
               external_calendar_sync_execution:,
               message: "Un second truc s'est produit",
               emitted_at: external_calendar_sync_execution.started_at + 0.2.seconds)
      end
    end
  end
end
