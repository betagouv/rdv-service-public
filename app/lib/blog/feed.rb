module Blog
  class Feed
    include Singleton
    include ActiveModel::Model

    attr_accessor :title, :link, :latest_post_at, :posts

    HEADWAY_URL = "https://headwayapp.co/rdv-service-public-changelog".freeze
    CACHE_KEY = "headway_html".freeze

    def initialize
      posts = HeadwayParser.new(headway_html_from_cache).posts
      self.title = "Nouveautés"
      self.link = HEADWAY_URL
      self.posts = posts
      self.latest_post_at = posts.map(&:published_at).max
      @loading_successful = posts.any?
    rescue StandardError => e
      Sentry.capture_exception(e)
      @loading_successful = false
    rescue WebMock::NetConnectNotAllowedError
      @loading_successful = false
    end

    def available?
      !!@loading_successful
    end

    def new_content_for_agent?(agent)
      return false unless available?
      return true if agent.blog_read_at.nil?

      latest_post_at > agent.blog_read_at
    end

    private

    def headway_html_from_cache
      Rails.cache.fetch(CACHE_KEY) { fetch_headway_html }
    end

    def refresh_cache
      Rails.cache.write(CACHE_KEY, html)
    end

    def fetch_headway_html
      Net::HTTP.get_response(URI(HEADWAY_URL)).body
    end
  end
end
