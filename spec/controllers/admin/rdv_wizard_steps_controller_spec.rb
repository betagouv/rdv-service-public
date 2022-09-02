# frozen_string_literal: true

describe Admin::RdvWizardStepsController, type: :controller do
  describe "GET index html format" do
    let(:motif) { create(:motif) }
    let(:organisation) { motif.organisation }
    let(:common_params) do
      {
        organisation_id: organisation.id,
        user_ids: [user.id],
        duration_in_min: 30,
        motif_id: motif.id,
        lieu_id: 1,
        starts_at: DateTime.new(2020, 4, 20, 8, 0, 0),
      }
    end

    let(:params) { common_params.merge(step: 2) }
    let!(:agent) { create(:agent, :secretaire, basic_role_in_organisations: [organisation]) }
    let!(:user) { create(:user) }

    before { sign_in agent }

    it "returns success" do
      get :new, params: params

      expect(assigns(:rdv).users).to eq([user])
      expect(response).to have_http_status(:success)
      expect(response).to render_template("admin/rdv_wizard_steps/step2")
    end

    describe "step 4" do
      render_views

      let(:params) { common_params.merge(step: 4) }

      it "shows the step 4" do
        get :new, params: params

        expect(assigns(:rdv).users).to eq([user])
        expect(response).to have_http_status(:success)
        expect(response).to render_template("admin/rdv_wizard_steps/step4")
      end

      context "when the user has no email nor phone_number" do
        let!(:user) { create(:user, :with_no_email, :with_no_phone_number) }

        it "shows a warning message" do
          get :new, params: params

          expect(response).to have_http_status(:success)
          expect(response.body).to include("cet usager ne possède pas de numéro de téléphone ou d'email")
        end
      end
    end
  end
end
