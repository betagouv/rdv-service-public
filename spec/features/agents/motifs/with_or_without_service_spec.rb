RSpec.describe "Activer et désactiver les services pour les motifs" do
  before { login_as(agent, scope: :agent) }

  let(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, service: nil, admin_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, organisation:) }

  describe "sans service" do
    it "n'affiche jamais les infos des service" do
      visit admin_organisation_motifs_path(organisation_id: organisation.id)
      expect(page).to have_content "Motifs de rendez-vous"

      expect(page).not_to have_content "Service"

      visit new_admin_organisation_motif_path(organisation_id: organisation.id)
      expect(page).not_to have_content "Service"

      visit admin_organisation_motif_path(organisation_id: organisation.id, id: motif.id)
      expect(page).not_to have_content "Service"

      visit edit_admin_organisation_motif_path(organisation_id: organisation.id, id: motif.id)
      expect(page).not_to have_content "Service"
    end
  end

  describe "quand on a activé les services sur le territoire, mais qu'on ne les a pas encore ajouté aux motifs" do
    let!(:service) { create(:service, territories: [organisation.territory]) }

    it "affiche les infos de service" do
      visit admin_organisation_motifs_path(organisation_id: organisation.id)
      expect(page).to have_content "Motifs de rendez-vous"

      expect(page).to have_content "Service"

      visit new_admin_organisation_motif_path(organisation_id: organisation.id)
      expect(page).to have_content "Service"

      visit admin_organisation_motif_path(organisation_id: organisation.id, id: motif.id)
      expect(page).to have_content "Service"

      visit edit_admin_organisation_motif_path(organisation_id: organisation.id, id: motif.id)
      expect(page).to have_content "Service"
    end
  end

  describe "quand on a désactivé les services sur le territoire, mais qu'on ne les a pas encore supprimé des motifs" do
    let!(:service) { create(:service, territories: []) }
    let!(:motif) { create(:motif, organisation:, service:) }

    it "affiche les infos de service, sauf sur le formulaire de création" do
      visit admin_organisation_motifs_path(organisation_id: organisation.id)
      expect(page).to have_content "Motifs de rendez-vous"

      expect(page).to have_content "Service"

      visit new_admin_organisation_motif_path(organisation_id: organisation.id)
      expect(page).not_to have_content "Service"

      visit admin_organisation_motif_path(organisation_id: organisation.id, id: motif.id)
      expect(page).to have_content "Service"

      visit edit_admin_organisation_motif_path(organisation_id: organisation.id, id: motif.id)
      expect(page).to have_content "Service"
    end
  end
end
