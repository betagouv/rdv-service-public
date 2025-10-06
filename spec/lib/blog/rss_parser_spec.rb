RSpec.describe Blog::RssParser do
  let(:rss_xml) { file_fixture("sites_faciles_rss.xml") }
  let(:parser) { described_class.new(rss_xml) }

  it "returns a list of posts" do
    expected_attrs = {
      title: "Article de blog #4",
      description: start_with("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam faucibus urna ut"),
      link: "http://sites.beta.gouv.fr/exemples/blog/article-de-blog-4/",
      published_at: Time.zone.parse("2024-09-25 17:39:00.000000000 +0200"),
    }
    expect(parser.posts.first).to have_attributes(expected_attrs)
  end
end
