FactoryBot.define do
  sequence(:login_code_email) { |n| "usager_#{n}@lapin.fr" }

  factory :login_code do
    email { generate(:login_code_email) }
    first_name { "Jean" }
    last_name { "Dupont" }
    code { SecureRandom.random_number(100_000..999_999).to_s }
    used_at { nil }
    domain_id { "RDV_SERVICE_PUBLIC" }
  end
end
