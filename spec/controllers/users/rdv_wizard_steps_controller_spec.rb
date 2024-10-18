RSpec.describe Users::RdvWizardStepsController, type: :controller do
  describe "#new" do
    let!(:organisation) { create(:organisation) }
    let!(:user) { create(:user) }
    let!(:motif) { create(:motif, organisation: organisation) }
    let!(:lieu) { create(:lieu, organisation: organisation) }
    let(:starts_at) { Time.zone.parse("2020-03-03 10h00") }
    let!(:mock_creneau) { instance_double(Creneau) }
    let!(:mock_rdv) { build(:rdv, starts_at: starts_at, users: [user], created_by: user) } # cannot use instance_double because it breaks pundit inference
    let(:mock_user_rdv_wizard) { instance_double(UserRdvWizard::Step2, creneau: mock_creneau, rdv: mock_rdv) }

    before { travel_to Date.parse("2020-03-01").in_time_zone + 8.hours }

    context "logged in user" do
      before do
        allow(UserRdvWizard::Step2).to \
          receive(:new).with(
            user,
            hash_including(
              "motif_id" => motif.id.to_s,
              "lieu_id" => lieu.id.to_s,
              "starts_at" => starts_at.to_s
            )
          ).and_return(mock_user_rdv_wizard)
      end

      context "when signed in" do
        before { sign_in user }

        it "return success" do
          get :new, params: { step: 2, motif_id: motif.id, lieu_id: lieu.id, starts_at: starts_at }
          expect(response).to have_http_status(:success)
          expect(assigns(:rdv).users).to eq([user])
          expect(response).to render_template("users/rdv_wizard_steps/step2")
        end
      end

      context "with invitation token" do
        let!(:invitation_token) { user.set_rdv_invitation_token! }

        before { request.session[:invitation] = { invitation_token:, expires_at: 10.hours.from_now } }

        it "return success" do
          get :new, params: { step: 2, motif_id: motif.id, lieu_id: lieu.id, starts_at: starts_at }
          expect(response).to have_http_status(:success)
          expect(assigns(:rdv).users).to eq([user])
          expect(response).to render_template("users/rdv_wizard_steps/step2")
        end
      end
    end

    context "without logged user" do
      it "redirects to sign_in path" do
        get :new, params: { step: 2, motif_id: motif.id, lieu_id: lieu.id, starts_at: starts_at }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
