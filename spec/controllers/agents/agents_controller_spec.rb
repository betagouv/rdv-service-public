RSpec.describe Agents::AgentsController, type: :controller do
  render_views

  let(:agent) { create(:agent, :admin) }
  let(:agent_invitee) { create(:agent, confirmed_at: nil, first_name: nil, last_name: nil) }
  let(:organisation_id) { agent.organisation_ids.first }

  before do
    sign_in agent
  end

  describe "GET #index" do
    it "returns a success response" do
      get :index, params: { organisation_id: organisation_id }
      expect(response).to be_successful
    end
  end

  describe "POST #reinvite" do
    it "returns a success response" do
      post :reinvite, params: { organisation_id: organisation_id, id: agent_invitee.to_param }
      expect(response).to redirect_to(organisation_agents_path(organisation_id))
    end
  end

  describe "DELETE #destroy" do
    subject { delete :destroy, params: { organisation_id: organisation_id, id: agent.to_param } }
    it "destroys the requested agent" do
      expect do
        subject
        agent.reload
      end.to change(agent, :deleted_at).from(nil)
    end

    it "redirects to the agents list" do
      subject
      expect(response).to redirect_to(organisation_agents_path(organisation_id))
    end
  end
end
