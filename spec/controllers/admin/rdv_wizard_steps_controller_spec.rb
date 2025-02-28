RSpec.describe Admin::RdvWizardStepsController, type: :controller do
  let(:motif) { create(:motif) }
  let(:organisation) { motif.organisation }
  let(:agent) { create(:agent, :secretaire, basic_role_in_organisations: [organisation]) }
  let(:user) { create(:user, organisations: [organisation]) }

  before { sign_in agent }

  describe "GET new" do
    let(:common_params) do
      {
        organisation_id: organisation.id,
        user_ids: [user.id],
        duration_in_min: 30,
        motif_id: motif.id,
        lieu_id: 1,
        starts_at: Time.zone.parse("2020-04-20 08:00"),
      }
    end

    let(:params) { common_params.merge(step: 2) }

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

      context "when the user has an email or a phone number" do
        it "shows the notification preferences" do
          get :new, params: params

          expect(response).to have_http_status(:success)
          expect(response.body).to include("Notifications de création et modification")
        end
      end

      context "when the user has no email nor phone_number" do
        let!(:user) { create(:user, :without_devise_email, :with_no_phone_number, organisations: [organisation]) }

        it "doesn't show the notification preferences" do
          get :new, params: params

          expect(response).to have_http_status(:success)
          expect(response.body).not_to include("Notifications de création et modification")
        end
      end
    end
  end

  describe "POST step4" do
    render_views

    subject(:create_request) { post :create, params: params }

    let(:lieu) { create(:lieu, organisation: organisation) }
    let(:starts_at) { 1.week.since }
    let(:params) do
      {
        organisation_id: organisation.id,
        step: 4,
        rdv: {
          motif_id: motif.id,
          lieu_id: lieu.id,
          starts_at: starts_at,
          duration_in_min: 30,
          agent_ids: [agent.id],
          user_ids: [user.id],
        },
      }
    end

    before { stub_netsize_ok }

    it "creates the rdv and flashes success" do
      expect { create_request }.to change(Rdv, :count).by(1)
      expect(flash[:success]).to match(/Le rendez-vous a été créé/)
    end

    context "when the rdv is in the past" do
      let(:starts_at) { 1.week.ago }

      it "shows a benign error" do
        expect { create_request }.not_to change(Rdv, :count)
        expect(response.body).to include("Ce rendez-vous a une date située dans le passé")
      end
    end
  end

  context "POST step2 avec motif téléphonique et l’usager a un numéro de téléphone" do
    render_views
    let!(:organisation) { create(:organisation) }
    let!(:motif) { create(:motif, :by_phone, organisation:) }
    let!(:agent) { create(:agent, service: motif.service, basic_role_in_organisations: [organisation]) }
    let!(:user) { create(:user, organisations: [organisation], first_name: "François", last_name: "Fictif", phone_number: "0606060606") }

    it "passe à l’étape suivante" do
      post(
        :create,
        params: {
          organisation_id: organisation.id,
          step: 2,
          rdv: {
            duration_in_min: 30,
            motif_id: motif.id,
            starts_at: 2.days.from_now,
            user_ids: [user.id],
          },
        }
      )
      expect(response.status).to eq(302)
      redirect_params = Rack::Utils.parse_query(URI.parse(response.location).query)
      expect(redirect_params["step"]).to eq("3")
      expect(flash[:error]).to be_nil
    end
  end

  context "POST step2 avec motif téléphonique mais l’usager n’a pas de numéro de téléphone" do
    render_views
    let!(:organisation) { create(:organisation) }
    let!(:motif) { create(:motif, :by_phone, organisation:) }
    let!(:agent) { create(:agent, service: motif.service, basic_role_in_organisations: [organisation]) }
    let!(:user) { create(:user, organisations: [organisation], first_name: "François", last_name: "Fictif", phone_number: nil) }

    it "affiche une erreur et ne passe pas à l’étape suivante" do
      post(
        :create,
        params: {
          organisation_id: organisation.id,
          step: 2,
          rdv: {
            duration_in_min: 30,
            motif_id: motif.id,
            starts_at: 2.days.from_now,
            user_ids: [user.id],
          },
        }
      )
      expect(response.body).to include("Aucun usager n’a de numéro de téléphone renseigné alors que le rendez-vous est téléphonique")
    end
  end
end
