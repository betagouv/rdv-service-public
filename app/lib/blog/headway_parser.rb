class Blog::HeadwayParser
  def initialize(html)
    @html = html
  end

  def posts
    doc = Nokogiri::HTML(@html)
    post_nodes = doc.css("div.changelogItem.published")
    post_nodes.map do |post_node|
      title_link = post_node.at_css("h2.title a")
      title = title_link&.text&.strip&.squish
      link = "https://headwayapp.co#{title_link&.[]('href')}"
      description = post_node.css('div[itemprop="articleBody"] p').map { |p| p.text.strip }.join(" ").squish
      published_at = Time.zone.parse(post_node.at_css("time")&.[]("datetime"))
      Blog::Post.new(title:, link:, description:, published_at:)
    end
  end
end
