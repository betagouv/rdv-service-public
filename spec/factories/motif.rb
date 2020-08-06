FactoryBot.define do
  sequence(:motif_name) { |n| "Motif #{n}" }

  factory :motif do
    organisation { create(:organisation) }
    service { create(:service) }

    name { generate(:motif_name) }
    default_duration_in_min { 45 }
    min_booking_delay { 30.minutes }
    max_booking_delay { 6.months }
    color { "##{SecureRandom.hex(3)}" }
    disable_notifications_for_users { false }
    instruction_for_rdv { "Intruction pour le RDV" }
    restriction_for_rdv { "Consigne pour le RDV" }
    reservable_online { true }
    location_type { :public_office }

    trait :with_rdvs do
      after(:create) do |motif|
        create_list(:rdv, 5, motif: motif, organisation: motif.organisation)
      end
    end
    trait :at_home do
      location_type { :home }
    end
    trait :at_public_office do
      location_type { :public_office }
    end
    trait :by_phone do
      location_type { :phone }
    end
    trait :for_secretariat do
      for_secretariat { true }
    end
    trait :no_notification do
      disable_notifications_for_users { true }
    end
  end
end
