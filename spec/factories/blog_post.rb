FactoryBot.define do
  factory :blog_post do
    sequence(:title) { |n| "Mon titre de post #{n}" }
    sequence(:description) { |n| "Ma description de post #{n}" }
    id { SecureRandom.uuid }
    external_url { "https://docs.numerique.gouv.fr/docs/#{id}" }
    published_at { 2.hours.ago }
  end
end
