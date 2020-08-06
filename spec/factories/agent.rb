FactoryBot.define do
  sequence(:agent_email) { |n| "agent_#{n}@lapin.fr" }

  factory :agent do
    organisations { [create(:organisation)] }
    service { create(:service) }

    email { generate(:agent_email) }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    password { "password" }
    confirmed_at { DateTime.parse("2020-07-30 10:30").in_time_zone }
    trait :admin do
      role { "admin" }
    end
    trait :not_confirmed do
      confirmed_at { nil }
    end
    trait :secretaire do
      service { Service.find_by(name: "Secrétariat") || create(:service, :secretariat) }
    end
    trait :with_multiple_organisations do
      organisations { create_list(:organisation, 3) }
    end
  end
end
