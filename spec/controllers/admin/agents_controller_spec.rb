RSpec.describe Admin::AgentsController, type: :controller do
  render_views

  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, :admin, organisations: [organisation]) }
  let!(:agent1) { create(:agent, :admin, organisations: [organisation]) }
  let(:agent_invitee) { create(:agent, confirmed_at: nil, first_name: nil, last_name: nil, organisations: [organisation]) }

  before do
    sign_in agent
  end

  describe "GET #index" do
    it "returns a success response" do
      get :index, params: { organisation_id: organisation.id }
      expect(response).to be_successful
    end
  end

  describe "POST #reinvite" do
    it "returns a success response" do
      post :reinvite, params: { organisation_id: organisation.id, id: agent_invitee.to_param }
      expect(response).to redirect_to(admin_organisation_agents_path(organisation))
    end
  end

  describe "DELETE #destroy" do
    subject { delete :destroy, params: { organisation_id: organisation.id, id: agent1.id } }
    it "destroys the requested agent" do
      expect { subject }.to change(Agent, :count).by(-1)
    end

    it "redirects to the agents list" do
      subject
      expect(response).to redirect_to(admin_organisation_agents_path(organisation))
    end
  end
end
