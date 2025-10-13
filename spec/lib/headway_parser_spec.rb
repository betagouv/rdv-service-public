RSpec.describe HeadwayParser do
  it "returns a list of posts" do
    expected_attrs = {
      title: "Mots de passe forts obligatoires",
      description: start_with("Dites adieu aux mots de passe vulnérables ! 👋🏼 Dans le cadre de notre démarche d'homologation"),
      categories: ["Sécurité"],
      link: "https://headwayapp.co/rdv-service-public-changelog/mots-de-passe-forts-obligatoires-314702",
      published_at: Time.zone.parse("2025-05-05 15:24:46.000000000 +0200"),
    }
    extracted_posts = described_class.extract_posts_from_html(file_fixture("headway_home.html"))
    expect(extracted_posts.size).to eq(3)
    expect(extracted_posts.first).to match(expected_attrs)
  end
end
