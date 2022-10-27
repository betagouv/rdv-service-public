# frozen_string_literal: true

FactoryBot.define do
  factory :zone do
    sector

    level { Zone::LEVEL_CITY }
    city_code do
      "#{sector.territory.departement_number}000"
    end
    city_name { "ARQUES" }

    trait :level_street do
      level { Zone::LEVEL_STREET }
    end
  end
end
