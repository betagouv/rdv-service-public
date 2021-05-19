# frozen_string_literal: true

FactoryBot.define do
  sequence(:city_code) { |n| (62_001 + n).to_s }

  factory :zone do
    sector

    level { Zone::LEVEL_CITY }
    city_code { generate(:city_code) }
    city_name { "ARQUES" }

    trait :level_street do
      level { Zone::LEVEL_STREET }
    end
  end
end
