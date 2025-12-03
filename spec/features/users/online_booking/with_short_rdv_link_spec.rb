RSpec.describe "Les usagers peuvent accéder à leur RDV via des liens court" do
  let(:rdv) { create(:rdv) }

  context "lorsqu’ils utilisent le lien court avec le token uniquement" do
    it "ils sont redirigés vers la page d’authentification avec le nom de famille puis vers la page du rendez-vous" do
      visit rdv_short_from_token_path(rdv.participations.first.restricted_auth_token)
      expect(page).to have_current_path(new_users_user_name_initials_verification_path)
      fill_in(:letters, with: rdv.participations.first.user.last_name[0..2].upcase)
      click_on "Valider"
      expect(page).to have_current_path(users_rdv_path(rdv))
    end
  end

  context "lorsqu’ils utilisent le lien court avec l’id et le token" do
    it "ils sont redirigés vers la page d’authentification avec le nom de famille puis vers la page du rendez-vous" do
      visit rdv_short_path(rdv.id, tkn: rdv.participations.first.restricted_auth_token)
      expect(page).to have_current_path(new_users_user_name_initials_verification_path)
      fill_in(:letters, with: rdv.participations.first.user.last_name[0..2].upcase)
      click_on "Valider"
      expect(page).to have_current_path(users_rdv_path(rdv))
    end
  end
end
