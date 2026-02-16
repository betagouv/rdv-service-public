RSpec.describe "Créneau devenu indisponible lors de la prise de RDV" do
  let(:now) { Time.zone.parse("2021-12-13 8:00") }
  let(:starts_at) { Time.zone.parse("2022-01-13 10:30") }

  let!(:territory) { create(:territory, departement_number: "92") }
  let!(:organisation) { create(:organisation, territory:) }
  let!(:motif) { create(:motif, organisation:) }
  let!(:lieu) { create(:lieu, organisation:) }
  let!(:user) { create(:user, organisations: [organisation]) }

  before do
    travel_to(now)
    login_as(user, scope: :user)
  end

  describe "#new" do
    it "redirige vers le moteur de recherche avec un message d'erreur" do
      visit new_users_rdv_wizard_step_path(motif_id: motif.id, lieu_id: lieu.id, starts_at: starts_at, departement: "92")
      expect(page).to have_current_path(prendre_rdv_path, ignore_query: true)
      expect(page).to have_content("Ce créneau n'est plus disponible. Veuillez en sélectionner un autre.")
    end
  end

  describe "#create" do
    let!(:plage_ouverture) do
      create(:plage_ouverture,
             organisation:, motifs: [motif], lieu:, first_day: starts_at.to_date,
             start_time: Tod::TimeOfDay.new(10, 30), end_time: Tod::TimeOfDay.new(12))
    end

    it "redirige vers le moteur de recherche avec un message d'erreur" do
      visit new_users_rdv_wizard_step_path(motif_id: motif.id, lieu_id: lieu.id, starts_at: starts_at, departement: "92")
      expect(page).to have_button("Confirmer mon RDV")
      plage_ouverture.destroy
      click_button "Confirmer mon RDV"
      expect(page).to have_current_path(prendre_rdv_path, ignore_query: true)
      expect(page).to have_content("Ce créneau n'est plus disponible. Veuillez en sélectionner un autre.")
    end
  end
end
