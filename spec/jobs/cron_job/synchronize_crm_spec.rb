RSpec.describe CronJob::SynchronizeCrm, type: :job do
  let(:compte_prod_url) { "https://demo.rdv-solidarites.fr/territories/1" }
  let(:notion_page) do
    Notion::Messages::Message.new(
      id: "page_id",
      url: "https://notion.so/page",
      properties: {
        "COMPTE PROD": { url: compte_prod_url },
        "Project name": { "title" => [{ "plain_text" => "Mon projet" }] },
      }
    )
  end
  let(:notion_client) { instance_double(Notion::Client) }

  before do
    allow(Notion::Client).to receive(:new).and_return(notion_client)
    allow(notion_client).to receive(:database_query).and_yield(Notion::Messages::Message.new(results: [notion_page]))
  end

  context "quand la clef NOTION_API_SECRET n'est pas définie" do
    before do
      ENV["NOTION_API_SECRET"] = nil
    end

    it "ne fait rien" do
      described_class.new.perform

      expect(notion_client).not_to have_received(:database_query)
    end
  end

  context "quand la clef NOTION_API_SECRET est définie" do
    before do
      ENV["NOTION_API_SECRET"] = "secret"
    end

    it "enqueue un job SynchronizeCrmPageJob pour chaque page Notion" do
      expect { described_class.new.perform }.to have_enqueued_job(SynchronizeCrmPageJob).with(
        notion_page_id: "page_id",
        account_url: compte_prod_url,
        notion_page_url: "https://notion.so/page",
        notion_page_title: "Mon projet"
      )
    end
  end
end
