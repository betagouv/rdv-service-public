FactoryBot.define do
  sequence(:territory_name) { |n| "Territoire n°#{n}" }
  sequence(:departement_number)

  factory :territory do
    name { generate(:territory_name) }
    departement_number { generate(:departement_number).to_s.rjust(2, "0") }
    sms_provider { "netsize" }
    sms_configuration { "a_key" }
  end

  trait :mairies do
    name { Territory::MAIRIES_NAME }
  end
end
