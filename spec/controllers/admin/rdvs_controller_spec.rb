# frozen_string_literal: true

describe Admin::RdvsController, type: :controller do
  render_views

  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
  let!(:user) { create(:user, first_name: "Marie", last_name: "Denis") }
  let!(:motif) { create(:motif, name: "Suivi", organisation: organisation, service: service, color: "#1010FF") }
  let!(:rdv) { create(:rdv, motif: motif, agents: [agent], users: [user], organisation: organisation) }

  before do
    sign_in agent
  end

  describe "GET index" do
    let(:lieu) { create(:lieu, organisation: organisation, name: "MDS Orgeval") }

    it "respond success and assign RDVS" do
      get(:index, params: {
            organisation_id: organisation.id,
            agent_id: agent.id,
            start: Time.zone.parse("20/07/2019 08:00"),
            end: Time.zone.parse("27/07/2019 09:00")
          })

      expect(response).to be_successful
      expect(assigns(:rdvs)).to eq([])
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      get :edit, params: { organisation_id: organisation.id, id: rdv.to_param }
      expect(response).to be_successful
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      it "redirects to the rdv" do
        lieu = create(:lieu, organisation: organisation)
        put :update, params: { organisation_id: organisation.id, id: rdv.to_param, rdv: { lieu_id: lieu.id } }
        expect(response).to redirect_to(admin_organisation_rdv_path(organisation, rdv))
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'edit' template)" do
        new_attributes = { duration_in_min: nil }
        put :update, params: { organisation_id: organisation.id, id: rdv.to_param, rdv: new_attributes }
        expect(response).to be_successful
        expect(response).to render_template(:edit)
      end

      it "does not change rdv" do
        new_attributes = { duration_in_min: nil }
        expect do
          put :update, params: { organisation_id: organisation.id, id: rdv.to_param, rdv: new_attributes }
        end.not_to change(rdv, :duration_in_min)
      end
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      get :show, params: { organisation_id: organisation.id, id: rdv.id }
      expect(response).to be_successful
    end
  end

  describe "DELETE destroy" do
    it "cancel rdv" do
      expect do
        delete :destroy, params: { organisation_id: organisation.id, id: rdv.id }
      end.to change(Rdv, :count).by(-1)
    end
  end
end
