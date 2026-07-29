RSpec.describe "Prise de RDV pour un motif téléphonique" do
  describe "validation du numéro de téléphone pour les motifs téléphoniques" do
    let!(:territory) { create(:territory, departement_number: "24") }
    let!(:organisation) { create(:organisation, territory:) }
    let!(:user) { create(:user, phone_number: nil) }
    let!(:motif) { create(:motif, :by_phone, organisation:) }
    let!(:lieu) { create(:lieu, organisation:) }
    let!(:plage_ouverture) do
      create(:plage_ouverture, :weekdays, first_day: Date.parse("2024-11-04"), motifs: [motif], lieu: lieu, organisation:, start_time: Tod::TimeOfDay.new(8), end_time: Tod::TimeOfDay.new(12))
    end

    before { travel_to Date.parse("2024-11-03").in_time_zone + 8.hours }
    before { login_as(user, scope: :user) }

    context "numéro de tel renseigné et valide" do
      it "confirme le RDV directement" do
        visit(new_users_rdv_wizard_step_path(departement: "24", motif_id: motif.id, lieu_id: lieu.id, starts_at: Time.zone.parse("2024-11-05 08:00")))
        expect(page).to have_content("Vos informations")
        fill_in :user_phone_number, with: "0130303030"
        click_button("Confirmer mon RDV")
        expect(page).to have_content("Votre rendez vous a été confirmé")
      end
    end

    context "numéro de tel non renseigné" do
      it "reste sur le formulaire et montre une erreur" do
        visit(new_users_rdv_wizard_step_path(departement: "24", motif_id: motif.id, lieu_id: lieu.id, starts_at: Time.zone.parse("2024-11-05 08:00")))
        expect(page).to have_content("Vos informations")
        click_button("Confirmer mon RDV")
        expect(page).to have_content("Le numéro de téléphone est obligatoire car le RDV aura lieu par téléphone")
      end
    end
  end

  describe "numéro non-mobile renseigné" do
    let!(:territory) { create(:territory, departement_number: "92") }
    let!(:organisation) { create(:organisation, territory:) }
    let!(:motif) { create(:motif, organisation:) }
    let!(:lieu) { create(:lieu, organisation:) }
    let!(:plage_ouverture) do
      create(:plage_ouverture, :weekdays, first_day: Date.parse("2024-11-04"), motifs: [motif], lieu: lieu, organisation:, start_time: Tod::TimeOfDay.new(8), end_time: Tod::TimeOfDay.new(12))
    end
    let!(:user) { create(:user, phone_number: "0130303030", organisations: [organisation]) }

    before { travel_to Date.parse("2024-11-03").in_time_zone + 8.hours }
    before { login_as(user, scope: :user) }

    it "affiche le warning numéro non-mobile" do
      visit new_users_rdv_wizard_step_path(motif_id: motif.id, lieu_id: lieu.id, departement: "92", starts_at: Time.zone.parse("2024-11-05 08:00"))
      expect(page).to have_content("Vous ne recevrez pas de SMS avec ce numéro non-mobile")
    end
  end
end
