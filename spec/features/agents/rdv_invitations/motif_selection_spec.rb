RSpec.describe "Choix du motif" do
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let(:user) { create(:user, email: nil, organisations: [organisation]) }
  let(:organisation) { create(:organisation) }

  before { login_as agent, scope: :agent }

  describe "quand il n'y a pas de motifs" do
    it "propose d'en ajouter un nouveau" do
      visit edit_motif_admin_organisation_rdv_invitations_path(organisation, user_id: user.id)

      expect(page).to have_content "Aucun motif de rendez-vous n'est disponible."
      click_on "Créer un motif"

      expect(page).to have_content "Choisissez le type du rendez-vous"
    end
  end

  describe "navigating back to a previous step" do
    it "works" do
      visit edit_motif_admin_organisation_rdv_invitations_path(organisation, user_id: user.id)

      click_on "Retour"
      expect(page).to have_content("Étape 1 sur 3")
    end
  end
end
