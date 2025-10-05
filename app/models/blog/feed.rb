module Blog
  class Feed
    include ActiveModel::Model

    attr_accessor :title, :description, :link, :last_built_at, :posts

    def self.new_content_for_agent?(agent)
      feed = load
      feed.last_built_at < agent.blog_read_at
    rescue StandardError => e
      Sentry.capture_exception(e)
      false
    end

    def self.load
      from_headway
    end

    def self.from_headway
      headway_html = Net::HTTP.get_response(URI("https://headwayapp.co/rdv-service-public-changelog")).body

      feed = new
      doc = Nokogiri::HTML(headway_html)

      post_nodes = doc.css('div.changelogItem.published')
      feed.posts = post_nodes.map do |post_node|
        title_link = post_node.at_css('h2.title a')
        title = title_link&.text&.strip
        link   = title_link&.[]('href')
        # Description = first <p> inside articleBody (can change to join all <p>)
        description = post_node.at_css('div[ itemprop="articleBody" ] p')&.text&.strip
        published_at = Time.zone.parse(post_node.at_css('time')&.[]('datetime'))
        Blog::Post.new(title:, link:, description:, published_at:)
      end

      feed.title = "Nouveautés"
      feed.link = "https://headwayapp.co/rdv-service-public-changelog"
      feed.description = "coucou"
      feed.last_built_at = feed.posts.map(&:published_at).max
      feed
    end

    def self.from_rss(rss_str)
      feed = new
      Nokogiri::XML::Document.parse(rss_str).xpath("//channel").each do |channel|
        feed.title = channel.xpath("//title")[0].content
        feed.link = channel.xpath("//link")[0].content
        feed.description = channel.xpath("//description")[0].content
        feed.last_built_at = Time.zone.parse(channel.xpath("//lastBuildDate")[0].content)
        feed.posts = channel.xpath("//item").map do |item|
          Blog::Post.from_xml_item(item)
        end
      end
      feed
    end

    def self.fetch_rss
      response = Net::HTTP.get_response(URI("https://aide-rdv-service-public.sites.beta.gouv.fr/nouveautes/rss/"))
      case response
      when Net::HTTPSuccess
        response.body
      else
        raise response.inspect
      end
    end

    def self.fetch_rss_stubbed
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
            <channel>
                <title>Blog</title>
                <link>http://sites.beta.gouv.fr/exemples/blog/</link>
                <description>Voici un exemple de d'index de blog. […]</description>
                <atom:link href="http://sites.beta.gouv.fr/exemples/blog/rss/" rel="self"/>
                <language>fr</language>
                <lastBuildDate>Wed, 25 Sep 2024 15:39:00 +0000</lastBuildDate>
                <item><title>Article de blog #4</title>
                    <link>
                    http://sites.beta.gouv.fr/exemples/blog/article-de-blog-4/</link>
                    <description>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam faucibus urna ut metus
                        porttitor sagittis vel sit amet velit. Curabitur […]
                    </description>
                    <pubDate>Wed, 25 Sep 2024 15:39:00 +0000</pubDate>
                </item>
                <item><title>Article de blog #3</title>
                    <link>
                    http://sites.beta.gouv.fr/exemples/blog/article-de-blog-2/</link>
                    <description>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam faucibus urna ut metus
                        porttitor sagittis vel sit amet velit. Curabitur […]
                    </description>
                    <pubDate>Tue, 24 Sep 2024 15:26:00 +0000</pubDate>
                </item>
                <item><title>Article de blog #2</title>
                    <link>
                    http://sites.beta.gouv.fr/exemples/blog/article-de-blog-3/</link>
                    <description>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam faucibus urna ut metus
                        porttitor sagittis vel sit amet velit. Curabitur […]
                    </description>
                    <pubDate>Fri, 20 Sep 2024 15:39:00 +0000</pubDate>
                </item>
                <item><title>Article de blog #1</title>
                    <link>
                    http://sites.beta.gouv.fr/exemples/blog/article-de-blog-1/</link>
                    <description>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque tristique quis tortor in
                        bibendum. Nullam rhoncus odio dolor, sit amet […]
                    </description>
                    <pubDate>Thu, 19 Sep 2024 13:26:00 +0000</pubDate>
                </item>
            </channel>
        </rss>
      XML
    end
  end
end
