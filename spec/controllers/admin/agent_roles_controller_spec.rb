# frozen_string_literal: true

RSpec.describe Admin::AgentRolesController, type: :controller do
  render_views

  let!(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let!(:agent_user) { create(:agent) }
  let!(:agent_role) { create(:agent_role, agent: agent_user, organisation: organisation) }

  before do
    sign_in agent
  end

  describe "GET #edit" do
    it "returns a success response" do
      get :edit, params: { organisation_id: organisation.id, id: agent_role.id }
      expect(response).to be_successful
    end
  end

  describe "POST #update" do
    subject do
      post :update, params: { organisation_id: organisation.id, id: agent_role.id, agent_role: { level: "admin" } }
      agent_role.reload
    end

    it "returns a success response" do
      subject
      expect(response).to redirect_to(admin_organisation_agents_path(organisation))
    end

    it "changes role" do
      expect { subject }.to change(agent_role, :level).from(AgentRole::LEVEL_BASIC).to(AgentRole::LEVEL_ADMIN)
    end
  end
end
