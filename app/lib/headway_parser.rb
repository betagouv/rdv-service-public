module HeadwayParser
  def self.extract_posts_from_html(html)
    doc = Nokogiri::HTML(html)
    post_nodes = doc.css("div.changelogItem.published")
    post_nodes.map do |post_node|
      title_link = post_node.at_css("h2.title a")
      title = title_link&.text&.strip&.squish
      categories = post_node.css(".category").map { _1.text.strip }
      link = "https://headwayapp.co#{title_link&.[]('href')}"
      description = post_node.css('div[itemprop="articleBody"] p').map { _1.text.strip }.join(" ").squish
      published_at = Time.zone.parse(post_node.at_css("time")&.[]("datetime"))
      { title:, categories:, description:, link:, published_at: }
    end
  end
end
