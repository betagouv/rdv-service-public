FactoryBot.define do
  sequence(:service_name) { |n| "Service #{n}" }

  factory :service do
    name { generate(:service_name) }
    trait :secretariat do
      name { 'Secrétariat' }
    end
    trait :pmi do
      name { 'PMI' }
    end

    after(:build) do |service|
      unless service.short_name.present?
        service.short_name = service.name
      end
    end
  end
end
