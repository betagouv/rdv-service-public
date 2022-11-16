# frozen_string_literal: true

FactoryBot.define do
  factory :prescripteur do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name.upcase }
    email { Faker::Internet.email }
    sequence(:phone_number) { |n| "060000#{n.to_s.rjust(4, '0')}" }
  end
end
