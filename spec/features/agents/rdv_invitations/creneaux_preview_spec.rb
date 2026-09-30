RSpec.describe "Aperçu des créneaux avant la confirmation" do
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:organisation) { create(:organisation) }

  let(:rdv_invitation) { create(:rdv_invitation, motif:, lieu:, user:, inviting_agent: agent) }

  let(:motif) { create(:motif, organisation:) }
  let(:lieu) { create(:lieu, organisation:) }
  let(:user) { create(:user, organisations: [organisation]) }

  before { login_as agent, scope: :agent }

  context "quand il n'y a aucun créneau disponible" do
    it "permet d'en ajouter des nouveaux" do
      visit new_admin_organisation_rdv_invitation_path(organisation, motif_id: motif.id, lieu_id: lieu.id, user_id: user.id)

      expect(page).to have_content("Il n'y a pas de créneau disponible pour ce motif.")
      click_on "Ajouter des plages d'ouverture"
      expect(page).to have_content("Renseigner mes disponibilités")
    end
  end

  context "avec des créneaux disponibles" do
    let(:now) { Time.zone.local(2026, 9, 30, 14, 0, 0) }

    let!(:plage_ouverture) do
      create(:plage_ouverture, :weekdays, motifs: [motif], lieu: lieu, organisation: organisation, first_day: 7.days.ago)
    end

    context "à partir de la semaine courante"

    it "affiche les créneaux que l'usager va voir", js: true do
      visit new_admin_organisation_rdv_invitation_path(organisation, motif_id: motif.id, lieu_id: lieu.id, user_id: user.id)
      click_on "Il y a des créneaux"
      expect(page).to have_content("8:00")
      expect(page).to have_content("8:45")

      find(".fr-btn.fr-icon-arrow-right-s-line").click
      expect(page).to have_content("7 oct.")
    end
  end
end
