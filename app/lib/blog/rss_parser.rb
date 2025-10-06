class Blog::RssParser
  def initialize(xml)
    @xml = xml
  end

  def posts
    posts = []
    Nokogiri::XML::Document.parse(@xml).xpath("//channel").each do |channel|
      channel.xpath("//item").each do |item|
        posts << Blog::Post.new(
          title: item.children.find { _1.name == "title" }.content,
          link: item.children.find { _1.name == "link" }.content.squish,
          description: item.children.find { _1.name == "description" }.content.squish,
          published_at: Time.zone.parse(item.children.find { _1.name == "pubDate" }.content),
        )
      end
    end
    posts
  end
end
