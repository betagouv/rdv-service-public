FactoryBot.define do
  factory :user_note do
    organisation
    user
    text { "Une note pour voir" }
  end
end
