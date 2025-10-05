class BlogPost
  class Source
    def initialize(url:, parser:)
      @url = url
      @parser = parser
    end

    def posts
      Rails.cache.fetch(@url) do
        fetched_str = Net::HTTP.get_response(URI(@url)).body
        parser.new(fetched_str).posts
      end
    end

    private

    def body_cache_key
      aaaa
    end
  end

  SOURCE_HEADWAY = Source.new(
    url: "https://headwayapp.co/rdv-service-public-changelog",
    parser: HeadwayParser
  )
  SOURCE_SITES_FACILES = Source.new(
    url: "https://aide-rdv-service-public.sites.beta.gouv.fr/nouveautes/rss/",
    parser: RssParser
  )

  def self.new_content_for_agent?(agent)
    feed = load
    feed.last_built_at < agent.blog_read_at
  rescue StandardError => e
    Sentry.capture_exception(e)
    false
  end
end
