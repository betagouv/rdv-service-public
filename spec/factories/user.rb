FactoryBot.define do
  require 'faker'

  sequence(:user_email) { |n| "usager_#{n}@lapin.fr" }

  factory :user do
    email { generate(:user_email) }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    phone_number { "0658032519" }
    birth_date { Date.new(1990, 10, 12) }
    address { "20 avenue de Ségur, Paris" }
    organisations { [Organisation.first || create(:organisation)] }
    password { "12345678" }
    password_confirmation { "12345678" }
    confirmed_at { Time.zone.now }
    caisse_affiliation { 'caf' }
    affiliation_number { '39012093812038' }
    family_situation { 'divorced' }
    logement { 'sdf' }
    number_of_children { 12 }
    trait :with_multiple_organisations do
      organisations { create_list(:organisation, 3) }
    end
    trait :with_no_email do
      email { nil }
      created_or_updated_by_agent { true }
    end
  end
end
