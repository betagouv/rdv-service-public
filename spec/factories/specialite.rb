FactoryBot.define do
  sequence(:specialite_name) { |n| "Specialite #{n}" }

  factory :specialite do
    name { generate(:specialite_name) }
  end
end
