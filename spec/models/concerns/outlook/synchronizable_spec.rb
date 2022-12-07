# frozen_string_literal: true

RSpec.describe Outlook::Synchronizable, type: :concern do
  describe "#sync_create_in_outlook_asynchronously create callback" do
    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    context "agent synced with outlook" do
      let(:organisation) { create(:organisation, id: 10) }
      let(:motif) { create(:motif, name: "Super Motif", location_type: :phone) }
      # We need to create a fake agent to initialize a RDV as they have a validation on agents which prevents us to control the data in its AgentsRdv
      let(:fake_agent) { create(:agent) }
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:rdv) { create(:rdv, id: 20, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), duration_in_min: 30, agents: [fake_agent]) }
      let(:agents_rdv) { create(:agents_rdv, id: 12, agent: agent, rdv: rdv) }

      before do
        stub_request(:post, "https://graph.microsoft.com/v1.0/me/Events")
          .with(
            body: "{\"subject\":\"Super Motif\",\"body\":{\"contentType\":\"HTML\",\"content\":\"plus d'infos dans RDV Solidarités: http://www.rdv-solidarites-test.localhost/admin/organisations/10/rdvs/20\"},\"start\":{\"dateTime\":\"2023-01-01T11:00:00+01:00\",\"timeZone\":\"Europe/Paris\"},\"end\":{\"dateTime\":\"2023-01-01T11:30:00+01:00\",\"timeZone\":\"Europe/Paris\"},\"location\":{\"displayName\":\"Par téléphone\"}}",
            headers: {
              "Accept" => "application/json", "Authorization" => "Bearer token", "Content-Type" => "application/json", "Expect" => "", "Return-Client-Request-Id" => "true", "User-Agent" => "RDVSolidarites",
            }
          )
          .to_return(status: 200, body: { id: "event_id" }.to_json, headers: {})

        agents_rdv.save
      end

      it "update the outlook_id of the agents_rdv" do
        expect(agents_rdv.reload.outlook_id).to eq("event_id")
      end
    end

    context "agent not synced with outlook" do
      let(:agent) { create(:agent) }
      let!(:agents_rdv) { create(:agents_rdv, agent: agent) }

      before do
        allow(Outlook::CreateEventJob).to receive(:perform_later)
      end

      it "does not call Outlook::CreateEventJob" do
        expect(Outlook::CreateEventJob).not_to have_received(:perform_later)
      end
    end

    context "agents_rdv already exists in outlook" do
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let!(:agents_rdv) { create(:agents_rdv, agent: agent, outlook_id: "abc") }

      before do
        allow(Outlook::CreateEventJob).to receive(:perform_later)
      end

      it "does not call Outlook::CreateEventJob" do
        expect(Outlook::CreateEventJob).not_to have_received(:perform_later)
      end
    end
  end

  describe "#sync_update_in_outlook_asynchronously" do
    context "exists in outlook and agent is synced" do
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:agents_rdv) { create(:agents_rdv, agent: agent, outlook_id: "abc") }

      before do
        allow(Outlook::UpdateEventJob).to receive(:perform_later)

        agents_rdv.sync_update_in_outlook_asynchronously
      end

      it "calls Outlook::UpdateEventJob" do
        expect(Outlook::UpdateEventJob).to have_received(:perform_later).with(agents_rdv)
      end
    end

    context "exists in outlook and agent is not synced" do
      let(:agent) { create(:agent) }
      let(:agents_rdv) { create(:agents_rdv, agent: agent, outlook_id: "abc") }

      before do
        allow(Outlook::UpdateEventJob).to receive(:perform_later)

        agents_rdv.sync_update_in_outlook_asynchronously
      end

      it "does not call Outlook::UpdateEventJob" do
        expect(Outlook::UpdateEventJob).not_to have_received(:perform_later)
      end
    end

    context "does not exists in outlook" do
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:agents_rdv) { create(:agents_rdv, agent: agent) }

      it "calls Outlook::CreateEventJob" do
        allow(Outlook::CreateEventJob).to receive(:perform_later)

        expect(Outlook::CreateEventJob).to receive(:perform_later).with(agents_rdv)

        agents_rdv.sync_update_in_outlook_asynchronously
      end
    end

    context "is cancelled and exists in outlook" do
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:agents_rdv) { create(:agents_rdv, agent: agent, outlook_id: "abc") }

      before do
        allow(agents_rdv.rdv).to receive(:cancelled?).and_return(true)
        allow(Outlook::DestroyEventJob).to receive(:perform_later)

        agents_rdv.sync_update_in_outlook_asynchronously
      end

      it "calls Outlook::DestroyEventJob" do
        expect(Outlook::DestroyEventJob).to have_received(:perform_later).with(agents_rdv)
      end
    end

    context "is cancelled and does not exist in outlook" do
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:agents_rdv) { create(:agents_rdv, agent: agent) }

      before do
        allow(agents_rdv.rdv).to receive(:cancelled?).and_return(true)
        allow(Outlook::DestroyEventJob).to receive(:perform_later)

        agents_rdv.sync_update_in_outlook_asynchronously
      end

      it "does not call Outlook::DestroyEventJob" do
        expect(Outlook::DestroyEventJob).not_to have_received(:perform_later)
      end
    end

    context "is soft_deleted and exists in outlook" do
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:agents_rdv) { create(:agents_rdv, agent: agent, outlook_id: "abc") }

      before do
        allow(agents_rdv.rdv).to receive(:soft_deleted?).and_return(true)
        allow(Outlook::DestroyEventJob).to receive(:perform_later)

        agents_rdv.sync_update_in_outlook_asynchronously
      end

      it "calls DestroyEventJob" do
        expect(Outlook::DestroyEventJob).to have_received(:perform_later)
      end
    end
  end

  describe "#sync_destroy_in_outlook_asynchronously" do
    context "agent synced with outlook and exists in outlook" do
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:agents_rdv) { create(:agents_rdv, agent: agent, outlook_id: "abc") }

      before do
        allow(Outlook::DestroyEventJob).to receive(:perform_later)

        agents_rdv.sync_destroy_in_outlook_asynchronously
      end

      it "calls Outlook::DestroyEventJob" do
        expect(Outlook::DestroyEventJob).to have_received(:perform_later).with(agents_rdv)
      end
    end

    context "agent not synced with outlook" do
      let(:agent) { create(:agent) }
      let(:agents_rdv) { create(:agents_rdv, agent: agent) }

      before do
        allow(Outlook::DestroyEventJob).to receive(:perform_later)

        agents_rdv.sync_destroy_in_outlook_asynchronously
      end

      it "does not call Outlook::CreateEventJob" do
        expect(Outlook::DestroyEventJob).not_to have_received(:perform_later)
      end
    end

    context "agents_rdv does not exist in outlook" do
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:agents_rdv) { create(:agents_rdv, agent: agent) }

      before do
        allow(Outlook::DestroyEventJob).to receive(:perform_later)

        agents_rdv.sync_destroy_in_outlook_asynchronously
      end

      it "does not call Outlook::CreateEventJob" do
        expect(Outlook::DestroyEventJob).not_to have_received(:perform_later)
      end
    end
  end
end
