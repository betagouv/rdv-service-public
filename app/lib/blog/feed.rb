module Blog
  class Feed
    include Singleton
    include ActiveModel::Model

    attr_accessor :title, :link, :latest_post_at, :posts

    HEADWAY_URL = "https://headwayapp.co/rdv-service-public-changelog".freeze
    CACHE_KEY = "headway_html".freeze

    def initialize
      self.posts = HeadwayParser.new(headway_html_from_cache).posts
      self.title = "Nouveautés"
      self.link = HEADWAY_URL
      self.latest_post_at = posts.map(&:published_at).max
    end

    def new_content_for_agent?(agent)
      latest_post_at > agent.blog_read_at
    end

    def agent_up_to_date!(agent)
      agent.update_columns(blog_read_at: latest_post_at) # rubocop:disable Rails/SkipsModelValidations
    end

    private

    def headway_html_from_cache
      Rails.cache.fetch(CACHE_KEY) { fetch_headway_html }
    end

    def refresh_cache
      Rails.cache.write(CACHE_KEY, fetch_headway_html)
    end

    def fetch_headway_html
      Net::HTTP.get_response(URI(HEADWAY_URL)).body
    end
  end
end
