require "rails_helper"

RSpec.describe Outlook::SyncEventJob do
  let(:client_double) { instance_double(Outlook::ApiClient) }
  let(:rdv) { create(:rdv, organisation: organisation, agents: [agent]) }
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let(:agents_rdv) { rdv.agents_rdvs.first }
  let(:organisation) { create(:organisation) }

  before do
    allow(Outlook::ApiClient).to receive(:new).with(an_instance_of(OutlookConfig)).and_return(client_double)
  end

  context "when the event needs to be created" do
    before do
      # On set le token ici pour éviter de déclencher les callbacks activerecord au moment de la création des agents_rdvs
      create(:outlook_config, agent:)
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
        expect(sentry_events.last.user).to eq({ email: agents_rdv.agent.email, id: agents_rdv.agent.id, role: "Agent" })
      end
    end
  end

  context "when the refresh token is definitively invalid" do
    let(:error_description) do
      "AADSTS700003: Device object was not found in the tenant 'ccf6a070-e1d8-11f1-b227-2e53240b5bb1' directory. " \
        "Trace ID: a5164a78-a2b9-429c-9ee9-17e4c4d9ad00 Correlation ID: d198772a-e1d8-11f1-ae25-2e53240b5bb1 Timestamp: 2026-11-16 14:18:33Z"
    end

    before do
      create(:outlook_config, agent:)
      allow(Outlook::ApiClient).to receive(:new).and_call_original

      stub_request(:post, "https://graph.microsoft.com/v1.0/me/Events").to_return(
        status: 401,
        body: {
          error: {
            code: "InvalidAuthenticationToken",
            message: "Invalid token lifetime.",
            innerError: {
              date: "2026-11-16T14:18:33",
              "request-id": "d94e1164-e1d8-11f1-95bf-2e53240b5bb1",
              "client-request-id": "dc3089ca-e1d8-11f1-a2e9-2e53240b5bb1",
            },
          },
        }.to_json
      )

      stub_request(:post, "https://login.microsoftonline.com/common/oauth2/v2.0/token").to_return(
        status: 400,
        body: {
          error: "invalid_grant",
          error_description: error_description,
          error_codes: [700_003],
          timestamp: "2026-11-16 14:18:33Z",
          trace_id: "a5164a78-a2b9-429c-9ee9-17e4c4d9ad00",
          correlation_id: "d198772a-e1d8-11f1-ae25-2e53240b5bb1",
          error_uri: "https://login.microsoftonline.com/error?code=700003",
          suberror: "device_authentication_failed",
        }.to_json
      )
    end

    it "destroys the outlook config, warns the agent by email and does not retry" do
      agents_rdv.update_columns(outlook_create_in_progress: true) # rubocop:disable Rails/SkipsModelValidations

      expect { described_class.perform_now(agents_rdv.id, nil, agent) }
        .to have_enqueued_mail(Agents::OutlookSyncMailer, :sync_disabled).with(
          params: { agent:, error_description:, error_uri: "https://login.microsoftonline.com/error?code=700003" }, args: []
        )
        .and have_enqueued_job(described_class).exactly(0).times

      expect(agent.reload.outlook_config).to be_nil
      expect(sentry_events.last.extra).to eq({ error_description: })
      expect(sentry_events.last.tags).to include(error_uri: "https://login.microsoftonline.com/error?code=700003")
    end
  end

  context "when the event is already in outlook and only needs to be updated" do
    before do
      agents_rdv.update(outlook_id: "stubbed_outlook_event_id")
      # On set le token ici pour éviter de déclencher les callbacks activerecord au moment de la création des agents_rdvs
      create(:outlook_config, agent:)
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
        create(:outlook_config, agent:)
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
        create(:outlook_config, agent:)
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
