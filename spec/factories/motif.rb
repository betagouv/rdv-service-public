FactoryBot.define do
  sequence(:motif_name) { |n| "Motif #{n}" }

  factory :motif do
    name { generate(:motif_name) }
    organisation { Organisation.first || create(:organisation) }
    default_duration_in_min { 45 }
    color { "##{SecureRandom.hex(3)}" }
    trait :with_rdvs do
      after(:create) do |motif|
        create_list(:rdv, 5, motif: motif)
      end
    end
    service { Service.first || create(:service) }
  end
end
