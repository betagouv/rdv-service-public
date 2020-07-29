FactoryBot.define do
  sequence(:city_code) { |n| (62001 + n).to_s }

  factory :zone do
    level { "city" }
    city_code { generate(:city_code) }
    city_name { "ARQUES" }
    organisation { build(:organisation, departement: "62") }
  end
end
