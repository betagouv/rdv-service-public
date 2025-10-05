class Blog::Feed
  def initialize(url:, parser:, cache_key:)
    @url = url
    @parser = parser
    @cache_key = cache_key
  end

  def posts
    Rails.cache.fetch("blog_feed:#{@url}") do
      fetched_str = Net::HTTP.get_response(URI(@url)).body
      @parser.new(fetched_str).posts
    end
  end
end
