describe Agents::RdvWizardStepsController, type: :controller do
  describe "GET index html format" do
    let!(:agent) { create(:agent, :secretaire) }
    let!(:organisation_id) { agent.organisation_ids.first }
    let!(:user) { create(:user) }

    before { sign_in agent }

    let(:params) do
      {
        step: 2,
     organisation_id: organisation_id,
     user: user.id,
     duration_in_min: 30,
     motif_id: 1,
     plage_ouverture_location: "18+Rue+des+Terres+au+Cur%C3%A9%2C+75013+Paris",
     starts_at: DateTime.new(2020, 4, 20, 8, 0, 0),
      }
    end

    it "return success" do
      get :new, params: params
      expect(response).to have_http_status(:success)
    end

    it "return success" do
      get :new, params: params
      expect(assigns(:user)).to eq(user)
    end

    it "return success" do
      get :new, params: params
      expect(response).to render_template("agents/rdv_wizard_steps/step2")
    end
  end
end
