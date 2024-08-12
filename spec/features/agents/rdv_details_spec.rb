RSpec.describe "Agent can see RDV details correctly" do
  before do
    travel_to(Time.zone.local(2022, 4, 4))
    login_as(agent, scope: :agent)
  end

  let(:organisation) { create(:organisation) }
  let(:service) { create(:service) }
  let(:starts_at) { Time.zone.local(2022, 4, 7).at_noon }
  let(:agent) { create(:agent, first_name: "Bruce", last_name: "Wayne", service: service, basic_role_in_organisations: [organisation]) }

  context "Motif is not collective" do
    let(:user) { create(:user) }
    let(:motif) { create(:motif, service: service, name: "Renseignements") }
    let(:rdv) { create(:rdv, agents: [agent], users: [user], motif: motif, organisation: organisation, starts_at: starts_at) }
    let!(:receipt) { create(:receipt, rdv: rdv, result: :sent, content: "Vous avez rendez-vous!") }
    let(:prescripteur) { create(:prescripteur, first_name: "Jean", last_name: "Valjean") }

    it "Allows listing RDVs and redirect to show" do
      visit admin_organisation_rdvs_path(organisation)
      expect(page).to have_text("Liste des RDV")
      click_link("Le jeudi 07 avril 2022")
      expect(page).to have_text("Renseignements")
      expect(page).to have_text("Bruce WAYNE")
    end

    it "displays the prescripteur when present" do
      rdv.participations.last.update!(created_by: prescripteur)
      visit admin_organisation_rdvs_path(organisation)
      expect(page).to have_content("Rendez-vous pris par Jean VALJEAN")
    end

    it "displays the agent prescripteur when present" do
      rdv.participations.last.update!(created_by: agent, created_by_agent_prescripteur: true)
      visit admin_organisation_rdvs_path(organisation)
      expect(page).to have_content("Rendez-vous pris par Bruce WAYNE")
    end

    it "Allows showing RDVs data and correctly displays user notifications and notif info" do
      visit admin_organisation_rdv_path(organisation, rdv)
      expect(page).to have_text("Contenu")
      expect(page).to have_text("Vous avez rendez-vous!")
      expect(page).to have_text(user.email)
      expect(page).to have_text(user.phone_number)
    end

    context "The rdv has multiple users" do
      let(:user2) { create(:user, :with_no_email, :with_no_phone_number) }

      before do
        create(:participation, user: user2, rdv: rdv)
      end

      it "User_count is correct" do
        expect(rdv.users_count).to eq 2
      end

      it "The second user has no email and no phone number" do
        visit admin_organisation_rdv_path(organisation, rdv)
        expect(page).to have_text(I18n.t("admin.users.notifications_preferences.sms_absent"))
        expect(page).to have_text(I18n.t("admin.users.notifications_preferences.email_absent"))
      end

      it "User's phone is not mobile" do
        user2.phone_number = "0101010101"
        user2.save
        visit admin_organisation_rdv_path(organisation, rdv)
        expect(page).to have_text(I18n.t("admin.users.notifications_preferences.sms_invalid"))
      end

      it "User's rdv all notifications are disabled" do
        first_participations = rdv.participations.first
        first_participations.send_lifecycle_notifications = false
        first_participations.send_reminder_notification = false
        first_participations.save
        visit admin_organisation_rdv_path(organisation, rdv)
        expect(page).to have_text(I18n.t("admin.participations.notifications_summary.none"))
      end

      it "User's rdv lifecycle notifications are disabled" do
        first_participations = rdv.participations.first
        first_participations.send_lifecycle_notifications = false
        first_participations.save
        visit admin_organisation_rdv_path(organisation, rdv)
        expect(page).to have_text(I18n.t("admin.participations.notifications_summary.lifecycle_off"))
      end

      it "User's rdv reminder notifications are disabled" do
        first_participations = rdv.participations.first
        first_participations.send_reminder_notification = false
        first_participations.save
        visit admin_organisation_rdv_path(organisation, rdv)
        expect(page).to have_text(I18n.t("admin.participations.notifications_summary.reminder_off"))
      end
    end

    context "when the rdv is over" do
      let(:starts_at) { 1.day.ago }

      it "allows editing the RDV status", :js do
        visit admin_organisation_rdv_path(organisation, rdv)
        find(".btn", text: "À renseigner").click
        expect do
          find("span", text: "Rendez-vous honoré").click
          sleep 1
        end.to change { rdv.reload.status }.to("seen")
      end
    end
  end

  context "Motif is collective" do
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }
    let(:motif) { create(:motif, :collectif, service: service, name: "Atelier Colectif") }
    let(:rdv) { create(:rdv, agents: [agent], users: [user, user2, user3], motif: motif, organisation: organisation, starts_at: starts_at, max_participants_count: 3) }
    let!(:receipt) { create(:receipt, rdv: rdv, result: :sent, content: "Vous avez rendez-vous!") }

    it "Rdv is full" do
      visit admin_organisation_rdv_path(organisation, rdv)
      expect(page).not_to have_content("Ajouter un participant")
      expect(page).to have_content("3/3(Complet)")
    end

    it "Rdv is not full" do
      rdv.max_participants_count = 5
      rdv.save
      visit admin_organisation_rdv_path(organisation, rdv)
      expect(page).to have_content("Ajouter un participant")
      expect(page).to have_content("3/5(2 places restantes)")
    end

    it "Rdv has no participants limit" do
      rdv.max_participants_count = nil
      rdv.save
      visit admin_organisation_rdv_path(organisation, rdv)
      expect(page).to have_content("Ajouter un participant")
      expect(page).to have_content("3/X(Pas de limite de places)")
    end
  end

  # Ce test a été ajouté suite à un crash de l'affichage de la page RDV
  # lorsque l'agent du RDV avait été hard deleted depuis le SuperAdmin.
  context "when agent has been hard deleted" do
    let(:rdv) { create(:rdv, organisation: organisation, created_by: agent) }
    let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

    it "does not display the link to the agenda" do
      rdv.agents.first.rdvs.destroy_all
      rdv.agents.first.destroy!
      visit admin_organisation_rdv_path(organisation, rdv)
      expect(page).not_to have_content("voir dans l'agenda")
    end
  end

  context "when the rdv is by visio" do
    let(:motif) { create(:motif, service: service, location_type: :visio) }
    let(:user) { create(:user) }

    context "when the agent participates in the rdv" do
      let(:rdv) { create(:rdv, agents: [agent], users: [user], motif: motif, organisation: organisation, starts_at: starts_at) }

      it "shows the link to start the visio" do
        visit admin_organisation_rdv_path(organisation, rdv)
        expect(page).to have_content "démarrer la visioconférence"
        expect(page).to have_content "Par visioconférence"
      end
    end

    context "when the agent does not participates in the rdv" do
      let(:rdv) { create(:rdv, agents: [create(:agent)], users: [user], motif: motif, organisation: organisation, starts_at: starts_at) }

      it "does not show the link to start the visio" do
        visit admin_organisation_rdv_path(organisation, rdv)
        expect(page).not_to have_content "démarrer la visioconférence"
        expect(page).to have_content "Par visioconférence"
      end
    end
  end
end
