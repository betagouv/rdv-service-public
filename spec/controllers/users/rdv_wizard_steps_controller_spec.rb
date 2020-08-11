describe Users::RdvWizardStepsController, type: :controller do
  describe "GET index html format" do
    let!(:organisation) { create(:organisation) }
    let!(:user) { create(:user) }
    let!(:motif) { create(:motif, organisation: organisation) }
    let!(:lieu) { create(:lieu, organisation: organisation) }
    let!(:plage_ouverture) { create(:plage_ouverture, :daily, first_day: Date.new(2019, 7, 22), motifs: [motif], lieu: lieu, organisation: organisation) }
    let!(:creneau) do
      build(
        :creneau,
        motif: motif,
        starts_at: Date.parse("2020-03-03").in_time_zone + 10.hours
      )
    end

    before { travel_to Date.parse("2020-03-01").in_time_zone + 8.hours }
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
