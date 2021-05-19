# frozen_string_literal: true

describe Admin::RdvWizardStepsController, type: :controller do
  describe "GET index html format" do
    let!(:organisation) { create(:organisation) }
    let(:params) do
      {
        step: 2,
        organisation_id: organisation.id,
        user_ids: [user.id],
        duration_in_min: 30,
        motif_id: 1,
        lieu_id: 1,
        starts_at: DateTime.new(2020, 4, 20, 8, 0, 0)
      }
    end
    let!(:agent) { create(:agent, :secretaire, basic_role_in_organisations: [organisation]) }
    let!(:user) { create(:user) }

    before { sign_in agent }

    it "returns success" do
      get :new, params: params

      expect(assigns(:rdv).users).to eq([user])
      expect(response).to have_http_status(:success)
      expect(response).to render_template("admin/rdv_wizard_steps/step2")
    end
  end
end
