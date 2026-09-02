FactoryBot.define do
  factory :external_calendar_sync_execution do
    agent { association(:agent) }
    calendar_url { "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id/" }
    started_at { Time.zone.now }
  end
end
