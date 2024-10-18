FactoryBot.define do
  require "faker"

  sequence(:user_email) { |n| "usager_#{n}@lapin.fr" }

  factory :user do
    email { generate(:user_email) }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name.upcase }
    phone_number do
      num = ""
      num = Faker::PhoneNumber.cell_phone until Phonelib.parse(num, "FR").valid?
      num
    end
    birth_date { Date.parse("1985-07-20") }
    address { "20 avenue de Ségur, Paris, 75012" }
    password { "coRrect!h0rse" }
    password_confirmation { "coRrect!h0rse" }
    confirmed_at { Time.zone.now }
    caisse_affiliation { "caf" }
    affiliation_number { "39012093812038" }
    family_situation { "divorced" }
    number_of_children { 12 }
    notes { "Super note" }
    logement { :locataire }
    responsible { nil }
    created_through { "user_sign_up" }
    trait :unconfirmed do
      confirmed_at { nil }
    end
    trait :with_no_email do
      email { nil }
    end
    trait :with_no_phone_number do
      phone_number { nil }
    end
    trait :unregistered do
      confirmed_at { nil }
      password { nil }
      password_confirmation { nil }
    end
    trait :relative do
      responsible { association(:user) }
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
