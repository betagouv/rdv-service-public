RSpec.describe SynchronizeCrmPageJob, type: :job do
  let(:notion_client) { instance_double(Notion::Client) }

  before do
    allow(Notion::Client).to receive(:new).and_return(notion_client)
    allow(notion_client).to receive(:update_page)
  end

  context "quand la clef NOTION_API_SECRET n'est pas définie" do
    let(:territory) { create(:territory) }

    stub_env_with(NOTION_API_SECRET: nil)

    it "ne fait rien" do
      described_class.new.perform(
        notion_page_id: "page_id",
        account_url: "https://demo.rdv-solidarites.fr/territories/#{territory.id}",
        notion_page_url: "https://notion.so/page",
        notion_page_title: "Mon projet"
      )

      expect(notion_client).not_to have_received(:update_page)
    end
  end

  context "quand la clef NOTION_API_SECRET est définie" do
    stub_env_with(NOTION_API_SECRET: "secret")

    context "quand la variable COMPTE PROD est un territory" do
      let(:territory) { create(:territory) }
      let(:organisation_a) { create(:organisation, territory: territory) }
      let(:organisation_b) { create(:organisation, territory: territory) }
      let!(:rdv_a) { create(:rdv, organisation: organisation_a) }
      let!(:rdv_b) { create(:rdv, organisation: organisation_b, created_at: Date.yesterday) }

      it "le nombre de RDV et la date du dernier RDV sont mis à jour dans la page Notion avec la somme des RDV de l'espace" do
        described_class.new.perform(
          notion_page_id: "page_id",
          account_url: "https://demo.rdv-solidarites.fr/territories/#{territory.id}",
          notion_page_url: "https://notion.so/page",
          notion_page_title: "Mon projet"
        )

        expect(notion_client).to have_received(:update_page).with(
          page_id: "page_id",
          properties: {
            "NOMBRE DE RDV" => 2,
            "DATE CREATION DERNIER RDV" => { start: rdv_a.created_at.strftime("%Y-%m-%d") },
            "DATE CREATION ESPACE" => { start: territory.created_at.strftime("%Y-%m-%d") },
            "NOMBRE AGENTS ACTIFS" => 0,
          }
        )
      end
    end

    context "quand la variable COMPTE PROD est une organisation" do
      let(:territory) { create(:territory) }
      let(:organisation) { create(:organisation, territory: territory) }
      let!(:rdv) { create(:rdv, organisation: organisation) }

      it "le nombre de RDV et la date du dernier RDV sont mis à jour dans la page Notion avec la somme des RDV de l'organisation" do
        described_class.new.perform(
          notion_page_id: "page_id",
          account_url: "https://demo.rdv-solidarites.fr/organisations/#{organisation.id}",
          notion_page_url: "https://notion.so/page",
          notion_page_title: "Mon projet"
        )

        expect(notion_client).to have_received(:update_page).with(
          page_id: "page_id",
          properties: {
            "NOMBRE DE RDV" => 1,
            "DATE CREATION DERNIER RDV" => { start: rdv.created_at.strftime("%Y-%m-%d") },
            "DATE CREATION ESPACE" => { start: territory.created_at.strftime("%Y-%m-%d") },
            "NOMBRE AGENTS ACTIFS" => 0,
          }
        )
      end
    end

    context "quand l'organisation n'a pas encore de RDV" do
      let(:territory) { create(:territory) }
      let(:organisation) { create(:organisation, territory: territory) }

      it "le nombre de RDV est mis à jour dans la page Notion avec 0 et la date du dernier RDV est nulle" do
        described_class.new.perform(
          notion_page_id: "page_id",
          account_url: "https://demo.rdv-solidarites.fr/organisations/#{organisation.id}",
          notion_page_url: "https://notion.so/page",
          notion_page_title: "Mon projet"
        )

        expect(notion_client).to have_received(:update_page).with(
          page_id: "page_id",
          properties: {
            "NOMBRE DE RDV" => 0,
            "DATE CREATION DERNIER RDV" => nil,
            "DATE CREATION ESPACE" => { start: territory.created_at.strftime("%Y-%m-%d") },
            "NOMBRE AGENTS ACTIFS" => 0,
          }
        )
      end
    end

    context "quand la variable COMPTE PROD est une organisation inconnue" do
      it "ne fait rien" do
        described_class.new.perform(
          notion_page_id: "page_id",
          account_url: "https://demo.rdv-solidarites.fr/organisations/26739",
          notion_page_url: "https://notion.so/page",
          notion_page_title: "Mon projet"
        )

        expect(notion_client).not_to have_received(:update_page)
      end
    end

    context "quand la variable COMPTE PROD est incorrecte" do
      before do
        allow(MattermostApiClient).to receive(:send_message)
      end

      it "envoie un message Mattermost" do
        described_class.new.perform(
          notion_page_id: "page_id",
          account_url: "https://demo.rdv-solidarites.fr/invalid/path",
          notion_page_url: "https://notion.so/page",
          notion_page_title: "Mon projet"
        )

        expect(MattermostApiClient).to have_received(:send_message).with(
          channel: "startup-rdv-alertes-crm",
          text: "L'URL du compte PROD de la carte Notion [Mon projet](https://notion.so/page), est incorrecte.",
          username: "CRM",
          icon_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Notion-logo.svg/100px-Notion-logo.svg.png"
        )
      end

      it "ne met pas à jour la page Notion" do
        described_class.new.perform(
          notion_page_id: "page_id",
          account_url: "https://demo.rdv-solidarites.fr/invalid/path",
          notion_page_url: "https://notion.so/page",
          notion_page_title: "Mon projet"
        )

        expect(notion_client).not_to have_received(:update_page)
      end
    end

    context "gestion des erreurs de l'API Notion" do
      let(:territory) { create(:territory) }
      let(:organisation) { create(:organisation, territory:) }
      let(:job_args) do
        {
          notion_page_id: "page_id",
          account_url: "https://demo.rdv-solidarites.fr/organisations/#{organisation.id}",
          notion_page_url: "https://notion.so/page",
          notion_page_title: "Mon projet",
        }
      end

      it "retente le job toutes les 5 minutes en cas de 429 (TooManyRequests)" do
        allow(notion_client).to receive(:update_page).and_raise(Notion::Api::Errors::TooManyRequests.new(Faraday::Response.new))
        described_class.perform_later(**job_args)
        expect(enqueued_jobs.size).to eq(1)
        perform_enqueued_jobs
        expect(enqueued_jobs.size).to eq(1)
        expect(enqueued_jobs.first["executions"]).to eq(1)
        expect(Time.zone.parse(enqueued_jobs.first["scheduled_at"])).to be > 4.minutes.from_now
      end

      it "descarte le job en cas d'erreur 404 (ObjectNotFound)" do
        allow(notion_client).to receive(:update_page).and_raise(Notion::Api::Errors::ObjectNotFound.new("not found", nil))
        described_class.perform_later(**job_args)
        expect(enqueued_jobs.size).to eq(1)
        perform_enqueued_jobs
        expect(enqueued_jobs).to be_empty
      end
    end
  end
end
