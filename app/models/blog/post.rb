module Blog
  class Post
    include ActiveModel::Model

    attr_accessor :title, :description, :link, :published_at

    def self.from_xml_item(item)
      new(
        title: item.children.find { _1.name == "title" }.content,
        link: item.children.find { _1.name == "link" }.content,
        description: item.children.find { _1.name == "description" }.content,
        published_at: Time.zone.parse(item.children.find { _1.name == "pubDate" }.content),
      )
    end
  end
end
