RSpec.describe Agents::PermissionsController, type: :controller do
  render_views

  let!(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, :admin, organisations: [organisation]) }
  let(:agent_user) { create(:agent, organisations: [organisation]) }

  before do
    sign_in agent
  end

  describe "GET #edit" do
    it "returns a success response" do
      get :edit, params: { organisation_id: organisation.id, id: agent_user.id }
      expect(response).to be_successful
    end
  end

  describe "POST #update" do
    subject do
      post :update, params: { organisation_id: organisation.id, id: agent_user.id, agent_permission: { role: "admin" } }
      agent_user.reload
    end

    it "returns a success response" do
      subject
      expect(response).to redirect_to(admin_organisation_agents_path(organisation))
    end

    it "changes role" do
      expect { subject }.to change(agent_user, :role).from("user").to("admin")
    end
  end
end
