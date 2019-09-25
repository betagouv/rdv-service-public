FactoryBot.define do
  sequence(:service_name) { |n| "Service #{n}" }

  factory :service do
    name { generate(:service_name) }
    organisation { Organisation.first || create(:organisation) }
  end
end
