class BlogPost < ApplicationRecord
  DOCS_URL = "https://docs.numerique.gouv.fr/docs/#{DocsNumeriqueChangelog::PARENT_DOCUMENT_ID}".freeze

  def self.new_content_for_agent?(agent)
    return false unless latest_post_at
    return true if agent.blog_read_at.nil?

    latest_post_at > agent.blog_read_at
  end

  def self.latest_post_at(cache_refresh: false)
    Rails.cache.fetch("blog_post_last_updated_at", force: cache_refresh) do
      maximum(:published_at)
    end
  end

  def self.refresh_from_posts(posts)
    transaction do
      delete_all
      posts.each(&:save!)
    end
    latest_post_at(cache_refresh: true)
  end
end
