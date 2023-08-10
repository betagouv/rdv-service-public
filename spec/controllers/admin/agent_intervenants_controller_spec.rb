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

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: { organisation_id: organisation.id }
      expect(response).to be_successful
      expect(assigns(:agent_intervenant)).to be_a_new(Agent)
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        last_name: "Intervenant",
        service_id: service.id,
      }
    end

    it "creates a new agent intervenant" do
      expect do
        post :create, params: { organisation_id: organisation.id, agent: valid_params }
      end.to change(Agent, :count).by(1)

      expect(response).to redirect_to(admin_organisation_agents_path(organisation))
      expect(flash[:notice]).to eq("Intervenant créé avec succès.")
    end

    it "renders new on failure" do
      post :create, params: { organisation_id: organisation.id, agent: { last_name: "" } }
      expect(unescaped_response_body).to include("Désignation doit être remplie")
      expect(response).to render_template(:new)
    end
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
      expect(response).to redirect_to(edit_admin_organisation_agent_role_path(organisation, agent_intervenant.roles.first))
      expect(flash[:error]).to eq("Désignation doit être remplie")
    end
  end
end
