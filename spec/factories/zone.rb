FactoryBot.define do
  sequence(:city_code) { |n| (62001 + n).to_s }

  factory :zone do
    sector { build(:sector, departement: "62") }

    level { "city" }
    city_code { generate(:city_code) }
    city_name { "ARQUES" }
  end
end
