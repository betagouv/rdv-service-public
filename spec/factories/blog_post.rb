FactoryBot.define do
  factory :blog_post do
    sequence(:title) { |n| "Mon titre de post #{n}" }
    sequence(:description) { |n| "Mon titre de description #{n}" }
    external_url { Faker::Internet.url }
    published_at { 2.hours.ago }
  end
end
