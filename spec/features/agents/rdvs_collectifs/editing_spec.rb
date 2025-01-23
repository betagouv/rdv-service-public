RSpec.describe "Agent can edit a Rdv collectif" do
  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, service: service, admin_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, :collectif, service: service, organisation: organisation, name: "Atelier Collectif") }
  let(:rdv) do
    create(:rdv,
           :without_users,
           motif: motif,
           organisation: organisation,
           agents: [agent],
           lieu: create(:lieu, organisation: organisation))
  end

  describe "doesn't send a cancellation notification if the notifications for the participant are removed" do
    let!(:user) { create(:user, phone_number: "+33611223344", email: "test@exemple.fr", organisations: [organisation]) }

    # js: true is necessary for the lieu selection
    it "works on common RDV edit page (edit_admin_organisation_rdv_path)", js: true do
      create(:participation, user: user, rdv: rdv, send_lifecycle_notifications: true)
      login_as(agent, scope: :agent)
      visit edit_admin_organisation_rdv_path(organisation, rdv)
      find(:label, text: "Notifications de création et modification").click

      expect do
        click_button "Enregistrer"
        expect(page).to have_content("Atelier Collectif") # to wait for the request to complete before checking sent emails
      end.not_to change { ActionMailer::Base.deliveries.size }

      expect(rdv.reload.participations.first.send_lifecycle_notifications).to be false
    end

    it "works on RDV collectif edit page (edit_admin_organisation_rdvs_collectif_path)" do
      login_as(agent, scope: :agent)
      visit edit_admin_organisation_rdvs_collectif_path(organisation, rdv, add_user: [user.id])
      find(:label, text: "Notifications de création et modification").click

      expect { click_button "Enregistrer" }.not_to change { ActionMailer::Base.deliveries.size }
      expect(rdv.reload.participations.first.send_lifecycle_notifications).to be false
    end
  end

  describe "injecting the ID of a user outside of the territory" do
    let!(:user) do
      create(:user, organisations: [organisation], first_name: "Francis", last_name: "Factice")
    end
    let(:organisation_from_other_territory) { create(:organisation, territory: create(:territory)) }
    let(:user_from_other_territory) do
      create(:user, organisations: [organisation_from_other_territory], first_name: "Gaston", last_name: "Bidon")
    end

    it "does not show injected user on page" do
      login_as(agent, scope: :agent)

      visit edit_admin_organisation_rdvs_collectif_path(organisation, rdv, add_user: [user.id])
      expect(page).to have_content("Francis")

      visit edit_admin_organisation_rdvs_collectif_path(organisation, rdv, add_user: [user_from_other_territory.id])
      expect(page).not_to have_content("Gaston")

      visit edit_admin_organisation_rdvs_collectif_path(organisation, rdv, add_user: [user.id, user_from_other_territory.id])
      expect(page).to have_content("Francis")
      expect(page).not_to have_content("Gaston")
    end
  end
end
