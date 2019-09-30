FactoryBot.define do
  require 'faker'

  sequence(:user_email) { |n| "usager_#{n}@lapin.fr" }

  factory :user do
    email { generate(:user_email) }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    phone_number { "0712121212" }
    birth_date { Date.new(1990, 10, 12) }
    address { "20 avenue de Ségur, Paris" }
    organisation { Organisation.first || create(:organisation) }
    password { "12345678" }
    confirmed_at { Time.zone.now }
  end
end
