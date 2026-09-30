FactoryBot.define do
  factory :blog_post do
    sequence(:title) { |n| "Mon titre de post #{n}" }
    sequence(:description) { |n| "Ma description de post #{n}" }
    external_url { "#{BlogPost::DOCS_DOCUMENT_URL_PREFIX}#{SecureRandom.uuid}" }
    published_at { 2.hours.ago }
  end
end
