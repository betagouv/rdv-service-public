RSpec.describe "User signs up and signs in" do
  context "for regular new user" do
    let(:user) { build(:user) }

    it "ne permet pas de créer un compte en arrivant depuis la page de connexion" do
      visit "http://www.rdv-solidarites-test.localhost/"
      click_link "Connexion Usager"
      expect(page).not_to have_content("Inscription")
      fill_in "Adresse email", with: user.email
      click_on "Recevoir un code de connexion"
      expect(page).to have_content("Aucun compte usager n’existe pour cet email")
    end
  end

  context "for invited user" do
    let(:invited_user) { create(:user, :unconfirmed) }

    it "can login via 6-digit code and gets confirmed" do
      visit "http://www.rdv-solidarites-test.localhost/"
      click_link "Connexion Usager"
      fill_in "Adresse email", with: invited_user.email
      click_on "Recevoir un code de connexion"
      fill_in "Code à 6 chiffres", with: LoginCode.most_recent_usable_for(email: invited_user.email).code
      click_on "Valider"
      expect(page).to have_content("Connexion réussie")
      expect(invited_user.reload).to be_confirmed
      click_on "Déconnexion"
      expect(page).to have_current_path(root_path, ignore_query: true)
    end
  end

  context "when an unconfirmed user already exists with the given email" do
    let!(:unconfirmed_user) { create(:user, :unconfirmed) }

    it "logs them in and confirms their account" do
      visit "http://www.rdv-aide-numerique-test.localhost/"
      click_link "Connexion Usager"
      fill_in "Adresse email", with: unconfirmed_user.email
      click_on "Recevoir un code de connexion"
      fill_in "Code à 6 chiffres", with: LoginCode.most_recent_usable_for(email: unconfirmed_user.email).code
      click_on "Valider"

      expect(page).to have_content("Connexion réussie")
      expect(unconfirmed_user.reload).to be_confirmed
    end
  end

  context "un agent essaie de se connecter depuis la page de connexion usagers" do
    let!(:agent) { create(:agent, email: "dulce@agent.fr", basic_role_in_organisations: [create(:organisation)]) }

    it "redirige vers la page de connexion agent" do
      visit "http://www.rdv-solidarites-test.localhost/"
      click_link "Connexion Usager"
      within("form") do
        fill_in "Adresse email", with: "dulce@agent.fr"
        click_on "Recevoir un code de connexion"
      end
      expect(page).to have_content(/Si vous souhaitez vous connecter en tant qu’agent/)
    end
  end
end
