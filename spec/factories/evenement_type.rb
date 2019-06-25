FactoryBot.define do
  sequence(:evenement_type_name) { |n| "Evenement Type #{n}" }

  factory :evenement_type do
    name { generate(:evenement_type_name) }
    default_duration_in_min { 45 }
    color { "##{SecureRandom.hex(3)}" }
    motif { build(:motif) }
  end
end
