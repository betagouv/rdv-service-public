FactoryBot.define do
  factory :organisation do
    name { Faker::Company.industry }
    territory

    trait :with_contact do
      email { Faker::Internet.email(name: name, domain: "orga.fr") }
      phone_number { Faker::PhoneNumber.phone_number }
      website { Faker::Internet.url }
    end
  end
end
