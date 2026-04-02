FactoryBot.define do
  sequence(:orga_name) { |n| "Organisation n°#{n}" }
  sequence(:orga_email) { |n| "contact#{n}@organisation.fr" }

  factory :organisation do
    name { generate(:orga_name) }
    territory

    trait :with_contact do
      email { generate(:orga_email) }
      phone_number { Faker::PhoneNumber.cell_phone }
      website { Faker::Internet.url }
    end
  end
end
