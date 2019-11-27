FactoryBot.define do
  sequence(:motif_name) { |n| "Motif #{n}" }
  factory :motif do
    name { generate(:motif_name) }
    organisation { Organisation.first || create(:organisation) }
    default_duration_in_min { 45 }
    min_booking_delay { 30.minutes }
    max_booking_delay { 6.months }
    color { "##{SecureRandom.hex(3)}" }
    disable_notifications_for_users { false }
    trait :with_rdvs do
      after(:create) do |motif|
        create_list(:rdv, 5, motif: motif)
      end
    end
    service { Service.first || create(:service) }
    trait :by_phone do
      by_phone { true }
    end
    trait :no_notification do
      disable_notifications_for_users { true }
    end
  end
end
