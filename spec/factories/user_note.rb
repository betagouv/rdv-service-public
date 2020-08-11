FactoryBot.define do
  factory :user_note do
    organisation
    user { association :user, organisations: [organisation] }
    agent { association :agent, organisations: [organisation] }
    text { "Une note pour voir" }
  end
end
