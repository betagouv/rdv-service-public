FactoryBot.define do
  factory :rdv_event do
    rdv { build(:rdv) }

    created_at { Time.zone.now }
    event_type { RdvEvent::TYPE_NOTIFICATION_SMS }
    event_name { "created" }
  end
end
