FactoryBot.define do
  factory :caldav_config do
    agent
    caldav_agenda_url { "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id" }
    caldav_username { "francis.factice@beta.gouv.fr" }
    caldav_password { "mot_de_passe_factice" }
  end
end
