FactoryBot.define do
  factory :super_admin do
    email { Faker::Internet.email(domain: "super-admin.fr") }
    role { :legacy_admin }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }

    trait :support do
      role { :support }
    end
  end
end
