FactoryBot.define do
  sequence(:super_admin_email) { |n| "super_admin_#{n}@lapin.fr" }

  factory :super_admin do
    email { generate(:super_admin_email) }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
  end
end
