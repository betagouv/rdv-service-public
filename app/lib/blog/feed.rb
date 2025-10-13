module Blog
  class Feed
    include ActiveModel::Model

    attr_accessor :title, :link, :latest_post_at, :posts

    HEADWAY_URL = "https://headwayapp.co/rdv-service-public-changelog".freeze
    CACHE_KEY = "blog_feed".freeze

    def self.new_content_for_agent?(agent)
      from_cache.latest_post_at > agent.blog_read_at
    rescue StandardError => e
      Sentry.capture_exception(e)
      false
    end

    def self.from_cache = Rails.cache.fetch(CACHE_KEY) { init_from_headway_website }
    def self.refresh_cache = Rails.cache.write(CACHE_KEY, init_from_headway_website)

    def self.init_from_headway_website
      headway_html = Net::HTTP.get_response(URI(HEADWAY_URL)).body
      feed = new
      feed.posts = HeadwayParser.new(headway_html).posts
      feed.title = "Nouveautés"
      feed.link = HEADWAY_URL
      feed.latest_post_at = feed.posts.map(&:published_at).max
      feed
    end
  end
end
