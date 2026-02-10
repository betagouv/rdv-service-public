class BlogPost < ApplicationRecord
  DOCS_URL = "https://docs.numerique.gouv.fr/docs/#{DocsNumeriqueChangelog::PARENT_DOCUMENT_ID}".freeze
  LATEST_POST_AT = maximum(:published_at)

  def self.new_content_for_agent?(agent)
    return false unless LATEST_POST_AT
    return true if agent.blog_read_at.nil?

    agent.blog_read_at < LATEST_POST_AT
  end

  def self.refresh_from_posts(posts)
    transaction do
      delete_all
      posts.each(&:save!)
    end
  end
end
