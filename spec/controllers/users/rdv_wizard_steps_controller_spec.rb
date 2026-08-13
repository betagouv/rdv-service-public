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

    context "usager connecté" do
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

      context "quand il est authentifié" do
        before { sign_in user }

        it "retourne un succès et affiche le formulaire" do
          get :new, params: { motif_id: motif.id, lieu_id: lieu.id, starts_at: starts_at }
          expect(response).to have_http_status(:success)
          expect(assigns(:rdv).users).to eq([user])
          expect(response).to render_template("users/rdv_wizard_steps/new")
        end
      end
    end

    context "usager non connecté" do
      it "redirige vers la page de connexion" do
        get :new, params: { motif_id: motif.id, lieu_id: lieu.id, starts_at: starts_at }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "#create" do
    let!(:organisation) { create(:organisation) }
    let!(:motif) { create(:motif, :at_public_office, organisation:, default_duration_in_min: 30) }
    let!(:lieu) { create(:lieu, organisation:) }
    let!(:plage_ouverture) { create(:plage_ouverture, :weekdays, organisation:, lieu:, motifs: [motif], first_day: Date.parse("2024-01-01")) }
    let(:starts_at) { Time.zone.parse("2024-01-08 09:00") }

    before { travel_to Date.parse("2024-01-01").in_time_zone + 8.hours }

    context "quand l'usager tente de modifier son email en bypassant le disabled HTML" do
      let!(:user) { create(:user, email: "original@exemple.fr") }

      before { sign_in user }

      it "ignore le paramètre email" do
        post :create, params: {
          rdv: { starts_at:, motif_id: motif.id, user_ids: [user.id] },
          user: { first_name: "Léa", last_name: "Boubakar", phone_number: nil, email: "hacked@exemple.fr" },
          selected_users: ["current_user"],
          departement: organisation.territory.departement_number,
        }
        expect(response).to have_http_status(:redirect) # pas d'erreur
        expect(user.reload).to have_attributes(email: "original@exemple.fr", first_name: "Léa", last_name: "Boubakar")
      end
    end

    context "quand l'usager invité pour la premiere fois via RDVI tente de modifier son email" do
      let!(:user) { create(:user, email: "original@exemple.fr", latest_login_at: nil) }
      let!(:invitation_token) { user.set_rdv_invitation_token! }

      before { request.session[:restricted_auth] = { invitation_token:, expires_at: 1.hour.from_now } }

      it "autorise la modification de l'email" do
        post :create, params: {
          rdv: { starts_at:, motif_id: motif.id, user_ids: [user.id] },
          user: { first_name: "Léa", last_name: "Boubakar", phone_number: nil, email: "nouvel@email.fr" },
          selected_users: ["current_user"],
          departement: organisation.territory.departement_number,
        }
        expect(response).to have_http_status(:redirect) # pas d'erreur
        expect(user.reload.email).to eq("nouvel@email.fr")
      end
    end
  end
end
