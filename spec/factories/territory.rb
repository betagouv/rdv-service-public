FactoryBot.define do
  sequence(:territory_name) { |n| "Territoire n°#{n}" }
  sequence(:departement_number)

  factory :territory do
    name { generate(:territory_name) }
    departement_number { generate(:departement_number) }
    sms_provider { "send_in_blue" }
    sms_configuration { { api_key: "a_key" } }
  end
end
