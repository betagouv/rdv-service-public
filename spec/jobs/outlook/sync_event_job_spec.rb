require "rails_helper"

RSpec.describe Outlook::SyncEventJob do
  let(:client_double) { instance_double(Outlook::ApiClient) }
  let(:rdv) { create(:rdv, organisation: organisation, agents: [agent]) }
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let(:agents_rdv) { rdv.agents_rdvs.first }
  let(:organisation) { create(:organisation) }

  before do
    allow(Outlook::ApiClient).to receive(:new).with(agent).and_return(client_double)
  end

  context "when the event needs to be created" do
    before do
      # On set le token ici pour éviter de déclencher les callbacks activerecord au moment de la création des agents_rdvs
      agent.update!(microsoft_graph_token: "token")
    end

    it "creates the event and updates the outlook_id" do
      allow(client_double).to receive(:create_event!).and_return("stubbed_outlook_event_id")
      described_class.perform_now(agents_rdv.id, agents_rdv.outlook_id, agents_rdv.agent)

      expect(agents_rdv.reload.outlook_id).to eq("stubbed_outlook_event_id")
    end

    context "when the call to the api fails" do
      it "retries the job, notifies the error monitoring, and does not update the outlook_id" do
        allow(client_double).to receive(:create_event!).and_raise("Outlook api error!")
        expect do
          described_class.perform_now(agents_rdv.id, nil, agents_rdv.agent)
        end.to have_enqueued_job(described_class).with(agents_rdv.id, nil, agents_rdv.agent)

        expect(agents_rdv.reload.outlook_id).to be_nil
        expect(sentry_events.last.exception.values.first.value).to eq("Outlook api error! (RuntimeError)")
      end
    end
  end

  context "when the event is already in outlook and only needs to be updated" do
    before do
      agents_rdv.update(outlook_id: "stubbed_outlook_event_id")
      # On set le token ici pour éviter de déclencher les callbacks activerecord au moment de la création des agents_rdvs
      agent.update!(microsoft_graph_token: "token")
    end

    it "creates the event and doesn't change the outlook_id" do
      expect(client_double).to receive(:update_event!)
      described_class.perform_now(agents_rdv.id, agents_rdv.outlook_id, agents_rdv.agent)

      expect(agents_rdv.reload.outlook_id).to eq("stubbed_outlook_event_id")
    end
  end

  context "when the event needs to be deleted" do
    context "because the rdv is cancelled" do
      before do
        agents_rdv.update!(outlook_id: "stubbed_outlook_event_id")
        rdv.update!(status: Rdv::CANCELLED_STATUSES.first)
        # On set le token ici pour éviter de déclencher les callbacks activerecord au moment de la création des agents_rdvs
        agent.update!(microsoft_graph_token: "token")
      end

      it "deletes it and removes the event_id" do
        expect(client_double).to receive(:delete_event!).with("stubbed_outlook_event_id")
        described_class.perform_now(agents_rdv.id, agents_rdv.outlook_id, agents_rdv.agent)

        expect(agents_rdv.reload.outlook_id).to be_nil
      end
    end

    context "because the agents_rdv is also deleted" do
      before do
        agents_rdv.update!(outlook_id: "stubbed_outlook_event_id")
        # On set le token ici pour éviter de déclencher les callbacks activerecord au moment de la création des agents_rdvs
        agent.update!(microsoft_graph_token: "token")
      end

      it "deletes it in the api" do
        agents_rdv.delete
        described_class.perform_later(agents_rdv.id, agents_rdv.outlook_id, agents_rdv.agent)

        expect(client_double).to receive(:delete_event!).with("stubbed_outlook_event_id")
        perform_enqueued_jobs
      end
    end
  end
end
