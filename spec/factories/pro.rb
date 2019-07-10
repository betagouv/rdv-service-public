FactoryBot.define do
  sequence(:pro_email) { |n| "pro_#{n}@lapin.fr" }

  factory :pro do
    email { generate(:pro_email) }
    first_name { Faker::Name.unique.first_name }
    last_name { Faker::Name.unique.last_name }
    password { 'password' }
    organisation { Organisation.first || create(:organisation) }
    confirmed_at { 1.day.ago }
    specialite { Specialite.first || create(:specialite) }
  end
end
