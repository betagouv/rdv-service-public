FactoryBot.define do
  sequence(:motif_name) { |n| "Motif #{n}" }

  factory :motif do
    name { generate(:motif_name) }
    specialite { build(:specialite) }
  end
end
