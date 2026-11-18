FactoryBot.define do
  factory :api_token do
    association :agent
    name { "Script cron" }
    duration { 1.month.to_i }
  end
end
