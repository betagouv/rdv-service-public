RSpec.describe DocsNumeriqueChangelog do
  let(:children_url) { "#{DocsNumeriqueChangelog::BASE_URL}/documents/#{DocsNumeriqueChangelog::PARENT_DOCUMENT_ID}/children/" }

  context "l'API retourne des documents" do
    before do
      stub_request(:get, children_url).to_return(
        status: 200,
        body: {
          "count" => 3,
          "results" => [
            { "id" => "doc-1", "title" => " Première fonctionnalité - 05/05/2025 - Nouveauté" },
            { "id" => "doc-2", "title" => "Incroyable amélioration - 01/05/2025 - Amélioration" },
            { "id" => "doc-3", "title" => " Une nouvelle page de réservation en ligne, pensée pour plus de clarté et d'autonomie - 17/10/2025 - Nouveauté" },
          ],
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

      stub_request(:get, "#{DocsNumeriqueChangelog::BASE_URL}/documents/doc-1/content/")
        .with(query: { content_format: "html" })
        .to_return(
          status: 200,
          body: { content: "<h1>Titre</h1><p>Ceci est le <strong>premier</strong> paragraphe.</p><p>Deuxième paragraphe.</p>" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:get, "#{DocsNumeriqueChangelog::BASE_URL}/documents/doc-2/content/")
        .with(query: { content_format: "html" })
        .to_return(
          status: 200,
          body: { content: "<p>Article sans description longue.</p>" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:get, "#{DocsNumeriqueChangelog::BASE_URL}/documents/doc-3/content/")
        .with(query: { content_format: "html" })
        .to_return(
          status: 200,
          body: { content: "<p>Description de la <a href='http://example.com'>nouvelle page</a>.</p>" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retourne une liste de BlogPost avec les attributs correctement parsés" do
      posts = described_class.fetch_and_parse_blog_posts

      expect(posts.size).to eq(3)
      expect(posts).to all(be_a(BlogPost))

      expect(posts.first).to have_attributes(
        title: "Première fonctionnalité",
        categories: ["Nouveauté"],
        description: "Titre Ceci est le premier paragraphe. Deuxième paragraphe.",
        external_url: "https://docs.numerique.gouv.fr/docs/doc-1",
        published_at: Time.zone.local(2025, 5, 5)
      )

      expect(posts.second).to have_attributes(
        title: "Incroyable amélioration",
        categories: ["Amélioration"],
        description: "Article sans description longue.",
        external_url: "https://docs.numerique.gouv.fr/docs/doc-2",
        published_at: Time.zone.local(2025, 5, 1)
      )

      expect(posts.third).to have_attributes(
        title: "Une nouvelle page de réservation en ligne, pensée pour plus de clarté et d'autonomie",
        categories: ["Nouveauté"],
        description: "Description de la nouvelle page.",
        external_url: "https://docs.numerique.gouv.fr/docs/doc-3",
        published_at: Time.zone.local(2025, 10, 17)
      )
    end
  end

  context "l'API retourne une liste vide" do
    before do
      stub_request(:get, children_url).to_return(
        status: 200,
        body: { "count" => 0, "results" => [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    end

    it "retourne une liste vide" do
      expect(described_class.fetch_and_parse_blog_posts).to eq([])
    end
  end

  context "l'API est indisponible" do
    before do
      stub_request(:get, children_url).to_timeout
    end

    it "lève une erreur" do
      expect { described_class.fetch_and_parse_blog_posts }.to raise_error(Faraday::ConnectionFailed)
    end
  end
end
