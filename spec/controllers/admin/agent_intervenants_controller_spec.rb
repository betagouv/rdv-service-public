# frozen_string_literal: true

RSpec.describe Admin::AgentIntervenantsController, type: :controller do
  render_views

  let!(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let!(:agent_intervenant) { create(:agent, :intervenant, organisations: [organisation]) }
  let(:service) { create(:service) }

  before do
    sign_in agent
  end

  describe "PUT #update" do
    let(:valid_update_params) do
      {
        last_name: "UpdatedName",
      }
    end

    it "updates the requested agent intervenant" do
      put :update, params: { organisation_id: organisation.id, id: agent_intervenant.id, agent: valid_update_params }
      agent_intervenant.reload

      expect(agent_intervenant.last_name).to eq("UpdatedName")
      expect(response).to redirect_to(admin_organisation_agents_path(organisation))
      expect(flash[:notice]).to eq("Intervenant modifié avec succès.")
    end

    it "renders edit on failure" do
      put :update, params: { organisation_id: organisation.id, id: agent_intervenant.id, agent: { last_name: "" } }
      expect(response).to redirect_to(edit_admin_organisation_agent_path(organisation, agent_intervenant))
      expect(flash[:error]).to eq("Nom d’usage doit être rempli(e)")
    end
  end
end
