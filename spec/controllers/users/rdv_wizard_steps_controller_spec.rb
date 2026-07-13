RSpec.describe Users::RdvWizardStepsController, type: :controller do
  describe "#new" do
    let!(:organisation) { create(:organisation) }
    let!(:user) { create(:user) }
    let!(:motif) { create(:motif, organisation: organisation) }
    let!(:lieu) { create(:lieu, organisation: organisation) }
    let(:starts_at) { Time.zone.parse("2020-03-03 10h00") }
    let!(:mock_creneau) { instance_double(Creneau) }
    let!(:mock_rdv) { build(:rdv, starts_at: starts_at, users: [user], created_by: user) } # cannot use instance_double because it breaks pundit inference
    let(:mock_user_rdv_builder) { instance_double(Users::RdvBuilder, creneau: mock_creneau, rdv: mock_rdv) }

    before { travel_to Date.parse("2020-03-01").in_time_zone + 8.hours }

    context "logged in user" do
      before do
        allow(Users::RdvBuilder).to \
          receive(:new).with(
            user,
            hash_including(
              "motif_id" => motif.id.to_s,
              "lieu_id" => lieu.id.to_s,
              "starts_at" => starts_at.to_s
            )
          ).and_return(mock_user_rdv_builder)
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
    end

    context "without logged user" do
      it "redirects to sign_in path" do
        get :new, params: { step: 2, motif_id: motif.id, lieu_id: lieu.id, starts_at: starts_at }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "usager connecté via une invitation" do
      before do
        sign_in user
        user.signed_in_with_invitation_token!
        allow(controller).to receive(:current_user).and_return(user)
        allow(Users::RdvBuilder).to receive(:new).and_return(mock_user_rdv_builder)
        allow(Users::RdvBookingForm).to receive(:new).and_return(instance_double(Users::RdvBookingForm))
      end

      it "le step 1 pointe vers le step 3 comme prochaine étape" do
        get :new, params: { step: 1, motif_id: motif.id, lieu_id: lieu.id, starts_at: starts_at }
        expect(controller.send(:next_step)[:number]).to eq(3)
      end
    end

    context "usager connecté via ProConnect" do
      let!(:user) { create(:user, pro_connect_openid_sub: "some-openid-sub") }

      before do
        sign_in user
        allow(Users::RdvBuilder).to receive(:new).and_return(mock_user_rdv_builder)
        allow(Users::RdvBookingForm).to receive(:new).and_return(instance_double(Users::RdvBookingForm))
      end

      it "le step 1 pointe vers le step 3 comme prochaine étape" do
        get :new, params: { step: 1, motif_id: motif.id, lieu_id: lieu.id, starts_at: starts_at }
        expect(controller.send(:next_step)[:number]).to eq(3)
      end
    end
  end

  describe "#create quand l'usager tente de modifier son email en bypassant le disabled HTML" do
    let!(:user) { create(:user, email: "original@exemple.fr") }
    let!(:organisation) { create(:organisation) }
    let!(:motif) { create(:motif, :at_public_office, organisation:, default_duration_in_min: 30) }

    before { sign_in user }

    it "ignore le paramètre email" do
      post :create, params: {
        rdv: { starts_at: 1.month.from_now, motif_id: motif.id, user_ids: [user.id] },
        user: { first_name: "Léa", last_name: "Boubakar", phone_number: nil, email: "hacked@exemple.fr" },
      }
      expect(response).to have_http_status(:redirect) # pas d'erreur
      expect(user.reload).to have_attributes(email: "original@exemple.fr", first_name: "Léa", last_name: "Boubakar")
    end
  end

  describe "#create quand l'usager invité pour la premiere fois via RDVI tente de modifier son email" do
    let!(:user) { create(:user, email: "original@exemple.fr", latest_login_at: nil) }
    let!(:organisation) { create(:organisation) }
    let!(:motif) { create(:motif, :at_public_office, organisation:, default_duration_in_min: 30) }
    let!(:invitation_token) { user.set_rdv_invitation_token! }

    before { request.session[:invitation] = { invitation_token:, expires_at: 1.hour.from_now } }

    it "autorise la modification de l'email" do
      post :create, params: {
        rdv: { starts_at: 1.month.from_now, motif_id: motif.id, user_ids: [user.id] },
        user: { first_name: "Léa", last_name: "Boubakar", phone_number: nil, email: "nouvel@email.fr" },
      }
      expect(response).to have_http_status(:redirect) # pas d'erreur
      expect(user.reload.email).to eq("nouvel@email.fr")
    end
  end
end
