FactoryBot.define do
  sequence(:motif_name) { |n| "Motif #{n}" }

  factory :motif do
    name { generate(:motif_name) }
    organisation { Organisation.first || build(:organisation) }
    default_duration_in_min { 45 }
    color { "##{SecureRandom.hex(3)}" }
    specialite
  end
end
