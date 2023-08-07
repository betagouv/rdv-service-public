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

  describe "PUT #update" do
    let(:invitation_email) { "jesuisunagent@intervenant.com" }

    context "when agent_role access_level is updated from admin to intervenant" do
      let(:agent_role) { create(:agent_role, :admin, agent: agent_user, organisation: organisation) }
      let(:agent_role_params) { { agent_role: { access_level: "intervenant" } } }

      it "updates the requested agent_role" do
        put :update, params: { organisation_id: organisation.id, id: agent_role.id }.merge(agent_role_params)
        expect(response).to redirect_to(admin_organisation_agents_path)
      end
    end

    context "when agent_role access_level is updated from admin to basic" do
      let(:agent_role) { create(:agent_role, :basic, agent: agent_user, organisation: organisation) }
      let(:agent_role_params) { { agent_role: { access_level: "basic" } } }

      it "updates the requested agent_role" do
        put :update, params: { organisation_id: organisation.id, id: agent_role.id }.merge(agent_role_params)
        expect(response).to redirect_to(admin_organisation_agents_path)
      end
    end

    context "when agent_role access_level is updated from intervenant to admin" do
      let(:agent_role) { create(:agent_role, :intervenant, agent: agent_user, organisation: organisation) }
      let(:agent_role_params) { { agent_role: { access_level: "admin", agent_attributes: { email: invitation_email } } } }

      it "updates the requested agent_role" do
        put :update, params: { organisation_id: organisation.id, id: agent_role.id }.merge(agent_role_params)
        expect(response).to redirect_to(admin_organisation_invitations_path)
      end
    end

    context "when agent_role access_level is updated from intervenant to admin with invalid params" do
      let(:agent_role) { create(:agent_role, :intervenant, agent: agent_user, organisation: organisation) }
      let(:agent_role_params) { { agent_role: { access_level: "admin", agent_attributes: { email: "bad-email" } } } }

      it "returns edit template with error" do
        put :update, params: { organisation_id: organisation.id, id: agent_role.id }.merge(agent_role_params)
        expect(unescaped_response_body).to include("Email n'est pas valide")
        expect(response).to render_template(:edit)
      end
    end
  end
end
