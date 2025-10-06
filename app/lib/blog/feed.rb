module Blog
  class Feed
    include ActiveModel::Model

    attr_accessor :title, :link, :latest_post_at, :posts

    SITES_FACILES_RSS_URL = "https://aide-rdv-service-public.sites.beta.gouv.fr/nouveautes/rss/".freeze
    CACHE_KEY = "blog_feed".freeze

    def self.new_content_for_agent?(agent)
      feed.latest_post_at < agent.blog_read_at
    rescue StandardError => e
      Sentry.capture_exception(e)
      false
    end

    def self.from_cache = Rails.cache.fetch(CACHE_KEY) { fetch }
    def self.refresh_cache = Rails.cache.write(CACHE_KEY, fetch)

    def self.fetch
      headway_html = Net::HTTP.get_response(URI(SITES_FACILES_RSS_URL)).body
      feed = new
      feed.posts = RssParser.new(headway_html).posts
      feed.title = "Nouveautés"
      feed.link = "https://aide-rdv-service-public.sites.beta.gouv.fr/nouveautes/"
      feed.latest_post_at = feed.posts.map(&:published_at).max
      feed
    end
  end
end
