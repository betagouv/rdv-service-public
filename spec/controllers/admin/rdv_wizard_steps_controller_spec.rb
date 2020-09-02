describe Admin::RdvWizardStepsController, type: :controller do
  describe "GET index html format" do
    let!(:agent) { create(:agent, :secretaire) }
    let!(:organisation_id) { agent.organisation_ids.first }
    let!(:user) { create(:user) }

    before { sign_in agent }

    let(:params) do
      {
        step: 2,
        organisation_id: organisation_id,
        user_ids: [user.id],
        duration_in_min: 30,
        motif_id: 1,
        lieu_id: 1,
        starts_at: DateTime.new(2020, 4, 20, 8, 0, 0),
      }
    end

    it "return success" do
      get :new, params: params
      expect(response).to have_http_status(:success)
    end

    it "return success" do
      get :new, params: params
      expect(assigns(:rdv).users).to eq([user])
    end

    it "return success" do
      get :new, params: params
      expect(response).to render_template("admin/rdv_wizard_steps/step2")
    end
  end
end
