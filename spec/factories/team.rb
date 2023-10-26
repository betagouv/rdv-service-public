# frozen_string_literal: true

FactoryBot.define do
  factory :team do
    territory { association(:territory) }
    name { Faker::Team.name }
  end
end
