FactoryBot.define do
  sequence(:service_name) { |n| "Service #{n}" }

  factory :service do
    name { generate(:service_name) }

    after(:build) do |service|
      service.short_name = service.name unless service.short_name.present?
    end

    trait :social do
      name { Service::SERVICE_SOCIAL }
    end

    trait :secretariat do
      name { Service::SECRETARIAT }
    end

    trait :pmi do
      name { Service::PMI }
    end
  end
end
