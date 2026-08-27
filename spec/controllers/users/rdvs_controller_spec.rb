RSpec.describe Users::RdvsController, type: :controller do
  render_views

  describe "PUT #cancel" do
    context "when user belongs to rdv" do
      let(:token) { rdv.participations.first.restricted_auth_token }
      let(:organisation) { create(:organisation) }
      let(:rdv) { create(:rdv, starts_at: 5.hours.from_now, organisation:) }

      it "calls update_and_notify function" do
        sign_in rdv.users.first
        expect_any_instance_of(Rdv::UpdateStatusAndNotify).to receive(:perform).and_call_original
        put :cancel, params: { id: rdv.id }
        expect(rdv.reload.status).to eq "excused"
      end

      it "redirects to the rdv" do
        sign_in rdv.users.first
        put :cancel, params: { id: rdv.id }
        expect(response).to redirect_to users_rdv_path(rdv)
      end

      context "when the motif is by phone and lieu is missing" do
        let(:rdv) { create(:rdv, motif: create(:motif, :by_phone, organisation:), lieu: nil, starts_at: 5.hours.from_now, organisation:) }

        before { sign_in rdv.users.first }

        it "calls update_and_notify function" do
          expect_any_instance_of(Rdv::UpdateStatusAndNotify).to receive(:perform).and_call_original
          put :cancel, params: { id: rdv.id }
          expect(rdv.reload.status).to eq "excused"
        end

        it "redirects to the rdv" do
          put :cancel, params: { id: rdv.id }
          expect(response).to redirect_to users_rdv_path(rdv)
        end
      end

      context "when rdv is not cancellable" do
        let(:rdv) { create(:rdv, starts_at: 3.hours.from_now, organisation:) }

        it "is not authorized" do
          sign_in rdv.users.first

          put :cancel, params: { id: rdv.id }
          expect(response).to redirect_to(users_rdvs_path)
          expect(flash[:error]).to eq("Vous n’avez pas les droits suffisants pour accéder à cette page ou effectuer cette action")
        end
      end
    end

    context "when user does not belongs to rdv" do
      let(:rdv) { create(:rdv, starts_at: 5.hours.from_now) }

      it "redirects and adds an error message" do
        other_user = create(:user)

        sign_in other_user

        put :cancel, params: { id: rdv.id }
        expect(response.status).to be(302)
        expect(flash[:error]).to include("Vous n’avez pas les droits suffisants")
      end
    end
  end

  describe "GET #show" do
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:organisation) { create(:organisation) }
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:rdv) { create(:rdv, users: [user], motif:, starts_at: starts_at, created_by: user, organisation:) }
    let(:rdv2) { create(:rdv, users: [user2], motif: create(:motif, :by_phone, organisation:), lieu: nil, starts_at: starts_at, created_by: user, organisation:) }
    let(:starts_at) { Time.zone.parse("2020-10-20 10h30") }
    let(:motif) { build(:motif, rdvs_editable_by_user: true, rdvs_cancellable_by_user: true, organisation:) }

    def prevents_access_to_others_rdvs
      get :show, params: { id: rdv2.id }
      expect(response.status).to be(302)
      expect(flash[:error]).to include("Vous n’avez pas les droits suffisants")
    end

    before do
      travel_to(Time.zone.parse("01/01/2019"))
      sign_in user
    end

    it "shows the rdv" do
      get :show, params: { id: rdv.id }

      expect(response).to be_successful
      expect(response.body).to match(/Votre RDV/)
      expect(response.body).to match(/Le mardi 20 octobre 2020/)
      expect(response.body).to match(/Déplacer le RDV/)
      expect(response.body).to match(/Annuler le RDV/)
    end

    context "when the motif is by phone and lieu is missing" do
      let(:rdv) { create(:rdv, users: [user], motif: create(:motif, :by_phone, organisation:), lieu: nil, starts_at: starts_at, created_by: user, organisation:) }

      it "shows the rdv" do
        get :show, params: { id: rdv.id }

        expect(response).to be_successful
        expect(response.body).to match(/Votre RDV/)
        expect(response.body).to match(/Le mardi 20 octobre 2020/)
        expect(response.body).to match(/Déplacer le RDV/)
        expect(response.body).to match(/Annuler le RDV/)
      end

      it "doesnt shows other's users rdv" do
        prevents_access_to_others_rdvs
      end
    end

    context "when the rdv is past" do
      let!(:starts_at) { Time.zone.parse("2018-12-31 10h30") }

      it "does show links to edit and cancel" do
        get :show, params: { id: rdv.id }

        expect(response).to be_successful
        expect(response.body).to match(/Votre RDV/)
        expect(response.body).not_to match(/Déplacer le RDV/)
        expect(response.body).not_to match(/Annuler le RDV/)
      end

      it "doesnt shows other's users rdv" do
        prevents_access_to_others_rdvs
      end
    end

    context "when the rdv is created by an agent" do
      let(:rdv) { create(:rdv, users: [user], motif: motif, starts_at: starts_at, created_by: agent, organisation:) }

      it "show links to edit and to cancel" do
        get :show, params: { id: rdv.id }

        expect(response).to be_successful
        expect(response.body).to match(/Votre RDV/)
        expect(response.body).to match(/Déplacer le RDV/)
        expect(response.body).to match(/Annuler le RDV/)
      end

      it "doesnt shows other's users rdv" do
        prevents_access_to_others_rdvs
      end
    end

    context "when the rdv motif is not bookable_by_everone" do
      let(:motif) { build(:motif, bookable_by: :agents, rdvs_editable_by_user: true, rdvs_cancellable_by_user: true, organisation:) }

      it "does show link to edit" do
        get :show, params: { id: rdv.id }

        expect(response).to be_successful
        expect(response.body).to match(/Votre RDV/)
        expect(response.body).not_to match(/Déplacer le RDV/)
        expect(response.body).to match(/Annuler le RDV/)
      end

      it "doesnt shows other's users rdv" do
        prevents_access_to_others_rdvs
      end
    end

    context "when the rdv is set as not editable" do
      let(:motif) { build(:motif, rdvs_editable_by_user: false, rdvs_cancellable_by_user: true, organisation:) }

      it "does show link to edit" do
        get :show, params: { id: rdv.id }

        expect(response).to be_successful
        expect(response.body).to match(/Votre RDV/)
        expect(response.body).not_to match(/Déplacer le RDV/)
        expect(response.body).to match(/Annuler le RDV/)
      end

      it "doesnt shows other's users rdv" do
        prevents_access_to_others_rdvs
      end
    end

    context "when the rdv is set as not cancellable" do
      let(:motif) { build(:motif, rdvs_editable_by_user: true, rdvs_cancellable_by_user: false, organisation:) }

      it "does show link to edit" do
        get :show, params: { id: rdv.id }

        expect(response).to be_successful
        expect(response.body).to match(/Votre RDV/)
        expect(response.body).to match(/Déplacer le RDV/)
        expect(response.body).not_to match(/Annuler le RDV/)
        expect(response.body).to match(/Ce rendez-vous n'est pas annulable en ligne/)
      end

      it "doesnt shows other's users rdv" do
        prevents_access_to_others_rdvs
      end
    end

    context "when the user is not signed in" do
      before do
        sign_out user
      end

      it "redirects to sign in path" do
        get :show, params: { id: rdv.id }

        expect(response).to redirect_to(new_user_session_path)
      end

      context "with a valid invitation token" do
        it "redirects to the identity verification form" do
          get :show, params: { id: rdv.id, invitation_token: rdv.participations.first.restricted_auth_token }

          expect(response).to redirect_to(new_users_user_name_initials_verification_path)
        end
      end
    end
  end

  describe "GET #index" do
    subject { get :index }

    let(:organisation) { create(:organisation) }
    let!(:user) { create(:user) }
    let!(:user2) { create(:user) }
    let!(:rdv1) { create(:rdv, users: [user], starts_at: 5.days.from_now, organisation:) }
    let!(:rdv2) { create(:rdv, users: [user], starts_at: 4.days.from_now, organisation:) }
    let!(:rdv3) { create(:rdv, motif: create(:motif, :by_phone, organisation:), lieu: nil, users: [user], starts_at: 3.days.from_now, organisation:) }
    let!(:rdv_co) { create(:rdv, :collectif, users: [user], starts_at: 6.days.from_now, organisation:) }
    let!(:rdv_co_other_user) { create(:rdv, :collectif, users: [user2], starts_at: 8.days.from_now) }
    let!(:rdv_co_without_users) { create(:rdv, :collectif, :without_users, starts_at: 9.days.from_now) }

    context "when signed in" do
      before { sign_in user }

      it "lists the rdvs" do
        subject

        expect(response).to be_successful
        expect(response.body).to include(I18n.l(rdv1.starts_at, format: :human).to_s)
        expect(response.body).to include(I18n.l(rdv2.starts_at, format: :human).to_s)
        expect(response.body).to include(I18n.l(rdv3.starts_at, format: :human).to_s)
        expect(response.body).to include(I18n.l(rdv_co.starts_at, format: :human).to_s)
        expect(response.body).not_to include(I18n.l(rdv_co_other_user.starts_at, format: :human).to_s)
        expect(response.body).not_to include(I18n.l(rdv_co_without_users.starts_at, format: :human).to_s)
      end

      context "when looking at rdvs on a different domain name" do
        before do
          controller.request.host = Domain::RDV_AIDE_NUMERIQUE.host_name
        end

        it "only shows the rdvs of the domain" do
          subject

          expect(response).to be_successful
          expect(response.body).not_to include(I18n.l(rdv1.starts_at, format: :human).to_s)
          expect(response.body).to include("pas de RDV à venir")
        end
      end
    end

    context "when not signed in" do
      it "redirects to sign in path" do
        subject

        expect(response).to redirect_to(new_user_session_path)
      end

      context "with a valid invitation token" do
        let!(:invitation_token) { user.set_rdv_invitation_token! }

        before do
          request.session[:restricted_auth] = { invitation_token: invitation_token, expires_at: 1.hour.from_now }
        end

        it "is not authorized" do
          get :index

          expect(response).to redirect_to(root_path)
          expect(flash[:error]).to eq("Vous n’avez pas les droits suffisants pour accéder à cette page ou effectuer cette action")
        end
      end
    end
  end

  describe "GET #creneaux" do
    subject do
      get :creneaux, params: { id: rdv.id }
      rdv.reload
    end

    let(:organisation) { create(:organisation) }
    let(:now) { Time.zone.parse("01/01/2019 10:00") }
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let!(:lieu) { create(:lieu, address: "10 rue de la Ferronerie, Nantes, 44100", organisation: organisation) }
    let!(:motif) { create(:motif, organisation: organisation, max_public_booking_delay: 2.weeks.to_i) }
    let!(:user) { create(:user) }
    let(:rdv) { create(:rdv, users: [user], starts_at: 5.days.from_now, lieu: lieu, motif: motif, organisation: organisation, created_by: user) }

    before do
      travel_to(now)
      sign_in user
    end

    context "no creneaux available" do
      before { subject }

      it { expect(response.body).to include("Malheureusement, tous les créneaux sont pris.") }
    end

    context "creneaux available" do
      before do
        # Une plage quotidienne qui commence dans 3 jours, ouvertures de 10h00 à 12h00
        create(:plage_ouverture, :weekdays,
               first_day: 3.days.from_now,
               start_time: Tod::TimeOfDay.new(10),
               end_time: Tod::TimeOfDay.new(12),
               lieu: lieu, agent: agent, motifs: [motif], organisation: organisation)

        # Une plage ponctuelle qui a lieu dans 2 jours, ouvertures de 16h00 à 17h00
        create(:plage_ouverture,
               first_day: 2.days.from_now,
               start_time: Tod::TimeOfDay.new(16),
               end_time: Tod::TimeOfDay.new(17),
               lieu: lieu, agent: agent, motifs: [motif], organisation: organisation)

        subject
      end

      it "spans 7 days: from first creneau day to 6 days after that" do
        expect(assigns(:date_range)).to eq(2.days.from_now.to_date..8.days.from_now.to_date)
      end

      it { expect(assigns(:creneaux)).not_to be_empty }

      specify do
        expect(response.body).to include("Voici les créneaux disponibles pour déplacer votre rendez-vous du")
        expect(response.body).to include("dimanche 6 janvier 2019 à 10h00")
        expect(response.body).to include("10:00") # heure de créneau pour la plage quotidienne
        expect(response.body).to include("16:00") # heure de créneau pour la plage ponctuelle
      end
    end

    context "when the rdv cannot be edited" do
      let(:rdv) { create(:rdv, users: [user], starts_at: 2.days.ago, lieu: lieu, motif: motif, organisation: organisation) }

      before { subject }

      it { expect(response).to redirect_to(users_rdvs_path) }
      it { expect(flash[:error]).to eq("Vous n’avez pas les droits suffisants pour accéder à cette page ou effectuer cette action") }
    end
  end

  describe "GET #edit" do
    subject do
      get :edit, params: { id: rdv.id, starts_at: starts_at }
      rdv.reload
    end

    let(:organisation) { create(:organisation) }
    let(:now) { Time.zone.parse("01/01/2019 10:00") }
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let!(:lieu) { create(:lieu, address: "10 rue de la Ferronerie, Nantes, 44100", organisation: organisation) }
    let!(:motif) { create(:motif, organisation: organisation) }
    let!(:user) { create(:user) }
    let(:rdv) { create(:rdv, users: [user], starts_at: 5.days.from_now, lieu: lieu, motif: motif, organisation: organisation, created_by: user) }
    let(:returned_creneau) { Creneau.new }

    before do
      travel_to(now)
      sign_in user
    end

    context "creneau is available" do
      let(:starts_at) { plage_ouverture.starts_at }
      let!(:plage_ouverture) do
        create(:plage_ouverture, :weekdays, motifs: [motif], lieu: lieu, organisation: organisation, agent: agent)
      end

      before { subject }

      it { expect(response.body).to include("Modification du RDV") }
      it { expect(response.body).to include("Confirmer le nouveau créneau") }

      context "when the motif is by phone and lieu is missing" do
        let(:motif) { create(:motif, :by_phone, organisation: organisation) }
        let(:lieu) { nil }

        it { expect(response.body).to include("Modification du RDV") }
        it { expect(response.body).to include("Confirmer le nouveau créneau") }
      end

      context "when the rdv is created by an agent" do
        let(:rdv) { create(:rdv, users: [user], starts_at: 5.days.from_now, lieu: lieu, motif: motif, organisation: organisation, created_by: agent) }

        before { subject }

        it { expect(response.body).to include("Modification du RDV") }
        it { expect(response.body).to include("Confirmer le nouveau créneau") }
      end
    end

    context "creneau isn't available" do
      let(:starts_at) { 3.days.from_now }

      before { subject }

      it { expect(response).to redirect_to(creneaux_users_rdv_path(rdv)) }
    end
  end

  describe "PUT #update" do
    let(:organisation) { create(:organisation) }
    let(:now) { Time.zone.parse("01/01/2019 10:00") }
    let(:starts_at) { 3.days.from_now }
    let(:user) { create(:user) }
    let(:motif) { create(:motif, organisation: organisation) }
    let(:lieu) { create(:lieu, address: "10 rue de la Ferronerie, Nantes, 44100", organisation: organisation) }
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:rdv) { create(:rdv, users: [user], starts_at: 5.days.from_now, lieu: lieu, motif: motif, organisation: organisation, created_by: user) }
    let(:token) { rdv.participations.last.restricted_auth_token }

    before do
      travel_to(now)
      sign_in user
    end

    context "with an available creneau" do
      let(:starts_at) { plage_ouverture.starts_at }
      let!(:plage_ouverture) do
        create(:plage_ouverture, :weekdays, motifs: [motif], lieu: lieu, organisation: organisation, agent: agent)
      end

      it "respond success and update RDV" do
        put :update, params: { id: rdv.id, starts_at: starts_at, agent_id: agent.id }
        expect(response).to redirect_to(users_rdv_path(rdv))
        expect(flash[:success]).to eq("Votre RDV a bien été modifié")
        expect(rdv.reload.starts_at).to eq(starts_at)
        expect(rdv.reload.agent_ids).to eq([agent.id])
      end

      context "when the motif is by phone and lieu is missing" do
        let(:motif) { create(:motif, :by_phone, organisation: organisation) }
        let(:lieu) { nil }

        it "respond success and update RDV" do
          put :update, params: { id: rdv.id, starts_at: starts_at, agent_id: agent.id }
          expect(response).to redirect_to(users_rdv_path(rdv))
          expect(flash[:success]).to eq("Votre RDV a bien été modifié")
          expect(rdv.reload.starts_at).to eq(starts_at)
          expect(rdv.reload.agent_ids).to eq([agent.id])
        end
      end

      context "when it cannot be updated" do
        before do
          allow_any_instance_of(Rdv).to receive(:update).and_return(false)
        end

        it "redirects to creneaux index" do
          put :update, params: { id: rdv.id, starts_at: starts_at, agent_id: agent.id }
          expect(response).to redirect_to(creneaux_users_rdv_path(rdv))
          expect(flash[:error]).to eq("Le RDV n'a pas pu être modifié")
        end
      end
    end

    context "without an available creneau" do
      let(:returned_creneau) { nil }

      it "redirect to index when not available" do
        put :update, params: { id: rdv.id, starts_at: starts_at, agent_id: agent.id }

        expect(response).to redirect_to(creneaux_users_rdv_path(rdv))
        expect(flash[:alert]).to eq("Ce créneau n'est plus disponible")
      end
    end
  end
end
