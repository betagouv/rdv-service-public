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
  let(:page_of_results) { Notion::Messages::Message.new(results: [notion_page, notion_page, notion_page, notion_page]) }
  let(:notion_client) { instance_double(Notion::Client) }

  before do
    allow(Notion::Client).to receive(:new).and_return(notion_client)
    # On simule 2 pages de résultats
    allow(notion_client).to receive(:database_query).and_yield(page_of_results).and_yield(page_of_results)
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

    let(:notion_pages) do
      [
        notion_page,
        notion_page,
        notion_page,
        notion_page,
      ]
    end

    it "enqueue un job SynchronizeCrmPageJob pour chaque page Notion" do
      expect { described_class.new.perform }.to have_enqueued_job(SynchronizeCrmPageJob).with(
        notion_page_id: "page_id",
        account_url: compte_prod_url,
        notion_page_url: "https://notion.so/page",
        notion_page_title: "Mon projet"
      ).exactly(8).times

      # On a stubbé 2 pages de 4 résultats
      expect(enqueued_jobs.size).to eq(8)

      # Les jobs sont scheduled pour s'exécuter à 400 ms d'intervalle
      0.upto(6) do |i|
        puts i.inspect
        expect(Time.zone.parse(enqueued_jobs[i + 1]["scheduled_at"]) - Time.zone.parse(enqueued_jobs[i]["scheduled_at"])).to be >= 0.4.seconds
      end
    end
  end
end
