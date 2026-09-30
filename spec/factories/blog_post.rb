FactoryBot.define do
  factory :blog_post do
    sequence(:title) { |n| "Mon titre de post #{n}" }
    sequence(:content_truncated_text) { |n| "Mon contenu de post #{n}" }
    content_html { "<p>#{content_truncated_text}</p>" }
    id { SecureRandom.uuid }
    external_url { "https://docs.numerique.gouv.fr/docs/#{id}" }
    published_at { 2.hours.ago }
  end
end
