RSpec.describe CronJob::RefreshBlogPostsFromDocsJob do
  let(:children_url) { "#{DocsNumeriqueChangelog::BASE_URL}/documents/#{DocsNumeriqueChangelog::PARENT_DOCUMENT_ID}/children/" }

  context "l'API docs.numerique.gouv.fr est disponible (fixtures)" do
    before do
      # Pour mettre à jour les fixtures : bin/rails runner spec/fixtures/files/update_docs_numerique_changelog_fixtures.rb
      #
      stub_request(:get, children_url)
        .to_return(status: 200, body: file_fixture("docs_numerique_changelog_children.json").read, headers: { "Content-Type" => "application/json" })

      stub_request(:get, "#{DocsNumeriqueChangelog::BASE_URL}/documents/3cc750d1-9bcf-4b3d-82bd-d9d232cc9de7/content/")
        .with(query: { content_format: "html" })
        .to_return(status: 200, body: file_fixture("docs_numerique_changelog_content_3cc750d1.json").read, headers: { "Content-Type" => "application/json" })

      stub_request(:get, "#{DocsNumeriqueChangelog::BASE_URL}/documents/c4853a77-99ff-4393-b68e-00b4b3429b03/content/")
        .with(query: { content_format: "html" })
        .to_return(status: 200, body: file_fixture("docs_numerique_changelog_content_c4853a77.json").read, headers: { "Content-Type" => "application/json" })

      stub_request(:get, "#{DocsNumeriqueChangelog::BASE_URL}/documents/3127498c-de81-41a1-b38e-3b9f0ae03083/content/")
        .with(query: { content_format: "html" })
        .to_return(status: 200, body: file_fixture("docs_numerique_changelog_content_3127498c.json").read, headers: { "Content-Type" => "application/json" })
    end

    it "crée les BlogPost en base" do
      expect { described_class.new.perform }.to change(BlogPost, :count).from(0).to(3)

      most_recent = BlogPost.order(published_at: :desc).first
      expect(most_recent).to have_attributes(
        title: "Vos RDV collectifs, désormais aussi en visioconférence",
        categories: ["Nouveauté"],
        description: start_with("Vous pouvez désormais proposer des rendez-vous collectifs en visioconférence."),
        external_url: "https://docs.numerique.gouv.fr/docs/3cc750d1-9bcf-4b3d-82bd-d9d232cc9de7",
        published_at: Time.zone.local(2026, 1, 15)
      )
    end
  end

  context "l'API docs.numerique.gouv.fr est indisponible" do
    before do
      create(:blog_post)
      stub_request(:get, children_url).to_timeout
    end

    it "remonte l'erreur à Sentry et relance le job" do
      expect(enqueued_jobs).to be_empty
      expect(sentry_events).to be_empty

      expect do
        described_class.perform_now
      end.not_to change { BlogPost.all.map(&:attributes) }

      next_try = enqueued_jobs.last
      expect(next_try[:job]).to eq(described_class)
      expect(next_try["exception_executions"]).to eq({ "[StandardError]" => 1 })
      expect(sentry_events.last.exception.values.first.value).to eq("execution expired (Net::OpenTimeout)")
    end
  end
end
