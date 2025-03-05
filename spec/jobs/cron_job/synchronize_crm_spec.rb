RSpec.describe CronJob::SynchronizeCrm, type: :job do
  let(:compte_prod_url) { "https://demo.rdv-solidarites.fr/territories/1" }
  let(:notion_page) { Notion::Messages::Message.new(id: "page_id", properties: { "COMPTE PROD": { url: compte_prod_url } }) }
  let(:notion_client) { instance_double(Notion::Client) }
  let(:territory) { create(:territory) }
  let(:organisation_a) { create(:organisation, territory: territory) }
  let(:organisation_b) { create(:organisation, territory: territory) }
  let!(:rdv_a) { create(:rdv, organisation: organisation_a) }
  let!(:rdv_b) { create(:rdv, organisation: organisation_b) }

  before do
    allow(Notion::Client).to receive(:new).and_return(notion_client)
    allow(notion_client).to receive(:database_query).and_yield(Notion::Messages::Message.new(results: [notion_page]))
    allow(notion_client).to receive(:update_page)
  end

  context "quand la clef NOTION_API_SECRET n’est pas définie" do
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

    context "quand la variable COMPTE PROD de la page Notion est un territoire" do
      let(:compte_prod_url) { "https://demo.rdv-solidarites.fr/territories/#{territory.id}" }

      it "le nombre de RDV est mis à jour dans la page Notion avec la somme des RDV du territoire" do
        described_class.new.perform

        expect(notion_client).to have_received(:update_page).with(page_id: "page_id", properties: { "NOMBRE DE RDV" => 2 })
      end
    end

    context "quand la variable COMPTE PROD de la page Notion est une organisation" do
      let(:compte_prod_url) { "https://demo.rdv-solidarites.fr/organisations/#{organisation_a.id}" }

      it "le nombre de RDV est mis à jour dans la page Notion avec la somme des RDV de l’organisation" do
        described_class.new.perform

        expect(notion_client).to have_received(:update_page).with(page_id: "page_id", properties: { "NOMBRE DE RDV" => 1 })
      end
    end

    context "quand la variable COMPTE PROD de la page Notion est une organisation inconnue" do
      let(:compte_prod_url) { "https://demo.rdv-solidarites.fr/organisations/26739" }

      it "retourne un compte nul" do
        described_class.new.perform

        expect(notion_client).to have_received(:update_page).with(page_id: "page_id", properties: { "NOMBRE DE RDV" => nil })
      end
    end
  end
end
