FactoryBot.define do
  factory :prescripteur do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name.upcase }
    email { Faker::Internet.email(name: last_name, domain: "prescripteur.fr") }
    phone_number { Faker::PhoneNumber.cell_phone }
  end
end
