# frozen_string_literal: true

FactoryBot.define do
  factory :team do
    territory { create(:territory) }
    name { Faker::Name.name }
  end
end
