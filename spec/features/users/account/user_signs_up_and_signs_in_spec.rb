RSpec.describe "User signs up and signs in" do
  context "for regular new user" do
    let(:user) { build(:user) }

    it "creates account via 6-digit code login and then signs out" do
      visit "http://www.rdv-solidarites-test.localhost/"
      click_link "Se connecter"
      fill_in "Prénom", with: user.first_name
      fill_in "Nom", with: user.last_name
      fill_in "Adresse email", with: user.email
      click_on "Recevoir un code de connexion"
      fill_in "Code à 6 chiffres", with: LoginCode.most_recent_usable_for(email: user.email).code
      click_on "Valider"
      expect(page).to have_content("Connexion réussie")
      expect(page).to have_content("Vos rendez-vous")
      click_link "Déconnexion"
      expect(page).to have_current_path(root_path, ignore_query: true)
    end
  end

  context "for invited user" do
    let(:invited_user) { create(:user, :unconfirmed) }

    it "can login via 6-digit code and gets confirmed" do
      visit "http://www.rdv-solidarites-test.localhost/"
      click_link "Se connecter"
      fill_in "Prénom", with: invited_user.first_name
      fill_in "Nom", with: invited_user.last_name
      fill_in "Adresse email", with: invited_user.email
      click_on "Recevoir un code de connexion"
      fill_in "Code à 6 chiffres", with: LoginCode.most_recent_usable_for(email: invited_user.email).code
      click_on "Valider"
      expect(page).to have_content("Connexion réussie")
      expect(invited_user.reload).to be_confirmed
      click_link "Déconnexion"
      expect(page).to have_current_path(root_path, ignore_query: true)
    end
  end

  context "when an unconfirmed user already exists with the given email" do
    let!(:unconfirmed_user) { create(:user, :unconfirmed) }

    it "logs them in and confirms their account" do
      visit "http://www.rdv-aide-numerique-test.localhost/"
      click_link "Se connecter"
      fill_in "Prénom", with: unconfirmed_user.first_name
      fill_in "Nom", with: unconfirmed_user.last_name
      fill_in "Adresse email", with: unconfirmed_user.email
      click_on "Recevoir un code de connexion"
      fill_in "Code à 6 chiffres", with: LoginCode.most_recent_usable_for(email: unconfirmed_user.email).code
      click_on "Valider"

      expect(page).to have_content("Connexion réussie")
      expect(unconfirmed_user.reload).to be_confirmed
    end
  end
end
