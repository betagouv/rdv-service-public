FactoryBot.define do
  require 'faker'

  sequence(:user_email) { |n| "usager_#{n}@lapin.fr" }

  factory :user do
    email { generate(:user_email) }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name.upcase }
    phone_number { Faker::PhoneNumber.phone_number }
    birth_date { Faker::Date.between(from: 80.years.ago, to: Date.today) }
    address { "20 avenue de Ségur, Paris" }
    password { "12345678" }
    password_confirmation { "12345678" }
    confirmed_at { Time.zone.now }
    caisse_affiliation { 'caf' }
    affiliation_number { '39012093812038' }
    family_situation { 'divorced' }
    number_of_children { 12 }
    responsible { nil }
    trait :unconfirmed do
      confirmed_at { nil }
    end
    trait :with_multiple_organisations do
      organisations { create_list(:organisation, 3) }
    end
    trait :with_no_email do
      email { nil }
    end
    trait :unregistered do
      confirmed_at { nil }
      password { nil }
      password_confirmation { nil }
    end
    trait :relative do
      phone_number { nil }
      address { nil }
      password { nil }
      password_confirmation { nil }
      confirmed_at { nil }
      caisse_affiliation { nil }
      affiliation_number { nil }
      family_situation { nil }
      number_of_children { nil }
    end
  end
end
