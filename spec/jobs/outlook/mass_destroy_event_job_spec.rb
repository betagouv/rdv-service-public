RSpec.describe Outlook::MassDestroyEventJob, type: :job do
  let(:organisation) { create(:organisation) }
  let(:motif) { create(:motif, name: "Super Motif", location_type: :phone, organisation:) }
  # We need to create a fake agent to initialize a RDV as they have a validation on agents which prevents us to control the data in its AgentsRdv
  let(:fake_agent) { create(:agent) }
  let(:agent) { create(:agent, :with_outlook_config) }
  let(:rdv) { create(:rdv, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), agents: [fake_agent]) }
  let(:rdv2) { create(:rdv, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 13h00"), agents: [fake_agent]) }
  let(:rdv3) { create(:rdv, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 15h00"), agents: [fake_agent]) }
  let(:rdv4) { create(:rdv, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 17h00"), agents: [fake_agent]) }
  let!(:agents_rdv) { create(:agents_rdv, agent: agent, rdv: rdv, outlook_id: "abc") }
  let!(:agents_rdv2) { create(:agents_rdv, agent: agent, rdv: rdv2, outlook_id: "def") }
  let!(:agents_rdv3) { create(:agents_rdv, agent: agent, rdv: rdv3) }
  let!(:agents_rdv4) { create(:agents_rdv, agent: agent, rdv: rdv4) }

  let(:expected_headers) do
    {
      "Accept" => "application/json",
      "Authorization" => "Bearer token",
      "Content-Type" => "application/json",
      "Expect" => "",
      "Return-Client-Request-Id" => "true",
      "User-Agent" => "RDVSolidarites",
    }
  end

  context "when the events are deleted successfully" do
    before do
      stub_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/abc")
        .with(headers: expected_headers)
        .to_return(status: 204, body: "", headers: {})
      stub_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/def")
        .with(headers: expected_headers)
        .to_return(status: 204, body: "", headers: {})
    end

    it "destroys the existing events in outlook" do
      expect do
        described_class.perform_now(agent)
      end.to change { agents_rdv.reload.outlook_id }.to(nil)
        .and change { agents_rdv2.reload.outlook_id }.to(nil)
    end

    it "unsyncs the agent" do
      expect do
        described_class.perform_now(agent)
      end.to change { agent.reload.outlook_config }.to(nil)
    end
  end

  context "when there is an ErrorItemNotFound error while destroying one of the events" do
    before do
      stub_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/abc")
        .with(headers: expected_headers)
        .to_return(status: 204, body: "", headers: {})
      stub_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/def")
        .with(headers: expected_headers)
        .to_return(
          status: 404,
          body: { error: { code: "ErrorItemNotFound", message: "The specified object was not found in the store." } }.to_json,
          headers: {}
        )
    end

    it "unsyncs the agent and clears the agents_rdvs.outlook_id column" do
      expect do
        described_class.perform_now(agent)
      end.to change { agent.reload.outlook_config }.to(nil)
        .and change { agents_rdv.reload.outlook_id }.to(nil)
        .and change { agents_rdv2.reload.outlook_id }.to(nil)
    end
  end

  context "when there is an unknown error while destroying one of the events" do
    before do
      stub_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/abc")
        .with(headers: expected_headers)
        .to_return(status: 204, body: "", headers: {})
      stub_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/def")
        .with(headers: expected_headers)
        .to_return(
          status: 500,
          body: { error: { code: "NeverSeenBeforeError", message: "Did not expect that one, did you?" } }.to_json,
          headers: {}
        )
    end

    it "retries the job but does no unlink agent nor agents_rdvs.outlook_id column for the RDV that triggered the error" do
      expect do
        described_class.perform_now(agent)
      end.to change(enqueued_jobs, :size).by(1) # job is re-enqueued

      expect(agent.reload.outlook_config.microsoft_graph_token).not_to be_nil
      expect(agent.reload.outlook_config.microsoft_graph_refresh_token).not_to be_nil
      expect(agents_rdv2.reload.outlook_id).not_to be_nil
    end
  end

  context "when the refresh token is definitively invalid" do
    before do
      stub_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/abc")
        .to_return(status: 401, body: { error: { code: "InvalidAuthenticationToken", message: "Access token has expired." } }.to_json)
      stub_request(:post, "https://login.microsoftonline.com/common/oauth2/v2.0/token")
        .to_return(status: 400, body: { error: "invalid_grant", error_description: "AADSTS700082: expired", error_codes: [700_082] }.to_json)
    end

    it "destroys the outlook config, warns the agent by email and does not retry" do
      expect do
        expect do
          described_class.perform_now(agent)
        end.to have_enqueued_mail(Agents::OutlookSyncMailer, :sync_disabled)
      end.not_to have_enqueued_job(described_class)

      expect(agent.reload.outlook_config).to be_nil
    end
  end
end
