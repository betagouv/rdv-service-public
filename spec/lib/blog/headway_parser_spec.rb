RSpec.describe Blog::HeadwayParser do
  let(:headway_html) { file_fixture("headway_home.html") }
  let(:parser) { described_class.new(headway_html) }

  it "returns a list of posts" do
    expected_attrs = {
      title: "Mots de passe forts obligatoires",
      description: start_with("Dites adieu aux mots de passe vulnérables ! 👋🏼 Dans le cadre de notre démarche d'homologation"),
      link: "https://headwayapp.co/rdv-service-public-changelog/mots-de-passe-forts-obligatoires-314702",
      published_at: Time.zone.parse("2025-05-05 15:24:46.000000000 +0200"),
    }
    expect(parser.posts.first).to have_attributes(expected_attrs)
  end
end
