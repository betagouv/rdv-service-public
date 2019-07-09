FactoryBot.define do
  sequence(:pro_email) { |n| "pro_#{n}@lapin.fr" }

  factory :pro do
    email { generate(:pro_email) }
    first_name { "Michel" }
    last_name { "Lapin" }
    password { 'password' }
    organisation { Organisation.first || build(:organisation) }
    confirmed_at { 1.day.ago }
  end
end
