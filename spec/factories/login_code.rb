FactoryBot.define do
  sequence(:login_code_email) { |n| "usager_#{n}@lapin.fr" }

  factory :login_code do
    email { generate(:login_code_email) }
    code { SecureRandom.random_number(100_000..999_999).to_s }
    used_at { nil }
    domain_id { "RDV_SERVICE_PUBLIC" }

    after(:build) { create(:user, email: _1.email) unless User.exists?(email: _1.email) } # necessary to pass validations
  end
end
