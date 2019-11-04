RSpec.describe Agents::PermissionsController, type: :controller do
  render_views

  let(:agent) { create(:agent, :admin) }
  let(:agent_user) { create(:agent) }
  let(:organisation_id) { agent.organisation_id }

  before do
    sign_in agent
  end

  describe "GET #edit" do
    it "returns a success response" do
      get :edit, params: { id: agent_user.id }
      expect(response).to be_successful
    end
  end

  describe "POST #update" do
    subject do
      post :update, params: { id: agent_user.id, agent_permission: { role: "admin" } }
      agent_user.reload
    end

    it "returns a success response" do
      subject
      expect(response).to redirect_to(organisation_agents_path(organisation_id))
    end

    it "changes role" do
      expect { subject }.to change(agent_user, :role).from("user").to("admin")
    end
  end
end
