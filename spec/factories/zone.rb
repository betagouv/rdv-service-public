FactoryBot.define do
  sequence(:city_code) { |n| (62_001 + n).to_s }

  factory :zone do
    sector

    level { "city" }
    city_code { generate(:city_code) }
    city_name { "ARQUES" }
  end
end
