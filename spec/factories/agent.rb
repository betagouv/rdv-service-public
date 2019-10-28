FactoryBot.define do
  sequence(:agent_email) { |n| "agent_#{n}@lapin.fr" }

  factory :agent do
    email { generate(:agent_email) }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    password { 'password' }
    organisations { [Organisation.first || create(:organisation)] }
    confirmed_at { 1.day.ago }
    service { Service.first || create(:service) }
    trait :admin do
      role { "admin" }
    end
    trait :secretaire do
      service { create(:service, :secretariat) }
    end
  end
end
