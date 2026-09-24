# On utilise une spec de controller pour manipuler la session plus facilement
RSpec.describe Agents::RdvPlansController do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:user) { create(:user, organisations: [organisation]) }
  let!(:lieu) { create(:lieu, organisation:) }
  let!(:motif) { create(:motif, organisation:, location_type: :visio) }

  let(:rdv_plan) do
    create(:rdv_plan, user:, motif:,
                      starts_at: 1.week.from_now,
                      duration_in_minutes: 30,
                      by_invitation:,
                      rdv_agent: agent,
                      planning_agent: agent)
  end

  before do
    sign_in agent

    session[:pro_connect_access_token] = "un-token"
    stub_request(:post, "#{VisioNumerique::CreateRoom::DEFAULT_API_URL}/rooms/")
      .to_return(status: 200, body: { url: "https://visio.numerique.gouv.fr/room-xyz" }.to_json, headers: { "Content-Type" => "application/json" })
  end

  context "for an invitation" do
    let(:by_invitation) { true }

    it "sets the custom visio url for the invitation" do
      post :create_rdv, params: { id: rdv_plan.id, rdv_plan: { user: { email: "francis@factice.org" }, participation: { send_lifecycle_notifications: true } } }

      expect(RdvInvitation.last.visio_url_custom).to eq("https://visio.numerique.gouv.fr/room-xyz")
    end
  end

  context "for a rdv" do
    let(:by_invitation) { false }

    it "sets the custom visio url for the rdv" do
      post :create_rdv, params: { id: rdv_plan.id, rdv_plan: { user: { email: "francis@factice.org" }, participation: { send_lifecycle_notifications: true, send_reminder_notification: true } } }

      expect(Rdv.last.visio_url_custom).to eq("https://visio.numerique.gouv.fr/room-xyz")
    end
  end
end
