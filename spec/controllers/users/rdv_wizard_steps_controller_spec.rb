describe Users::RdvWizardStepsController, type: :controller do
  describe "GET index html format" do
    let!(:user) { create(:user) }
    let!(:motif) { create(:motif) }
    let!(:lieu) { create(:lieu) }
    let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu) }
    let!(:creneau) { build(:creneau, motif: motif, starts_at: 10.days.from_now.change(hour: 10)) }

    before { sign_in user }

    let(:params) do
      {
        step: 2,
        motif_id: motif.id,
        lieu_id: lieu.id,
        starts_at: creneau.starts_at,
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
      expect(response).to render_template("users/rdv_wizard_steps/step2")
    end
  end
end
