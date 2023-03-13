# frozen_string_literal: true

require "rails_helper"

RSpec.describe Outlook::SyncEventJob do
  context "when the event needs to be created" do
    let(:client_double) { instance_double(Outlook::ApiClient) }
    let(:rdv) { create(:rdv, organisation: organisation, agents: [agent]) }
    let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
    let(:agents_rdv) { rdv.agents_rdvs.first }
    let(:organisation) { create(:organisation) }

    before do
      allow(Outlook::ApiClient).to receive(:new).with(agent).and_return(client_double)
    end

    before do
      # On set le token ici pour éviter de déclencher les callbacks activerecord au moment de la création des agents_rdvs
      agent.update!(microsoft_graph_token: "token")
    end

    it "creates the event and updates the outlook_id" do
      expect(client_double).to receive(:create_event!).and_return("stubbed_outlook_event_id")
      described_class.perform_now(agents_rdv, agents_rdv.outlook_id)

      expect(agents_rdv.reload.outlook_id).to eq("stubbed_outlook_event_id")
    end

    context "when the call to the api fails" do
      before do
        stub_request(:post, "https://graph.microsoft.com/v1.0/me/Events")
          .with(
            body: expected_body,
            headers: expected_headers
          ).to_return(status: 404, body: { error: { code: "TerribleError", message: "Quelle terrible erreur" } }.to_json, headers: {})
      end

      stub_sentry_events

      it "retries the job, notifies the error monitoring, and does not update the outlook_id" do
        expect do
          described_class.perform_now(agents_rdv)
        end.to have_enqueued_job(described_class).with(agents_rdv)

        expect(agents_rdv.reload.outlook_id).to eq(nil)
        expect(sentry_events.last.exception.values.first.value).to eq("Outlook Events API error: Quelle terrible erreur (RuntimeError)")
      end
    end
  end

  context "when the event needs to be updated" do
  end

  context "when the event needs to be deleted" do
    context "and it has already been deleted" do
    end
  end
end
