FactoryBot.define do
  sequence(:pro_email) { |n| "pro_#{n}@lapin.fr" }

  factory :pro do
    email { generate(:pro_email) }
    password { 'password' }
  end
end
