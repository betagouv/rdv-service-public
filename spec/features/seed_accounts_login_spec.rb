RSpec.describe "Connexion en un clic avec les comptes seeds" do
  it "en review app RDVS, page agent : un clic connecte l'agent" do
    with_modified_env(IS_REVIEW_APP: "true", DB_SEEDS_USERS_AND_AGENTS_PASSWORD: "Rdvservicepublictest1!") do
      _agent = create(:agent, first_name: "Martine", last_name: "Validay", email: "martine@demo.rdv-solidarites.fr", password: "Rdvservicepublictest1!")
      visit new_agent_session_path
      expect(page).to have_content("Connexion avec un compte de démo")
      click_on "martine"
      expect(page).to have_content("Martine VALIDAY")
      expect(page).to have_content("Pour commencer") # page d'accueil nouveau compte
    end
  end

  it "en review app RDVS, page usager : un clic envoie un code de connexion" do
    with_modified_env(IS_REVIEW_APP: "true", DB_SEEDS_USERS_AND_AGENTS_PASSWORD: "Rdvservicepublictest1!") do
      create(:user, email: "patricia_duroy@demo.rdv-solidarites.fr")

      visit new_user_session_path
      expect(page).to have_content("Connexion avec un compte de démo")
      click_on "patricia_duroy"
      expect(page).to have_content("code à 6 chiffres")
      expect(LoginCode.last.email).to eq("patricia_duroy@demo.rdv-solidarites.fr")
    end
  end

  it "en review app RDVS, n'affiche que les comptes du domaine courant et ceux sans domaine" do
    with_modified_env(IS_REVIEW_APP: "true") do
      visit new_agent_session_path
      expect(page).to have_button("martine")
      expect(page).to have_button("camille-clavier")
      expect(page).not_to have_button("alain.mairie")
    end
  end

  it "en review app RDVSP, affiche les comptes RDVSP et pas ceux de RDVS" do
    with_modified_env(IS_REVIEW_APP: "true", REVIEW_APP_DOMAIN: "RDV_SERVICE_PUBLIC") do
      visit new_agent_session_path
      expect(page).to have_button("alain.mairie")
      expect(page).to have_button("camille-clavier")
      expect(page).not_to have_button("martine")
    end
  end

  it "en production, n'affiche pas le bloc des comptes seeds" do
    with_modified_env(IS_REVIEW_APP: nil) do
      visit new_agent_session_path
      expect(page).not_to have_content("Connexion avec un compte de démo")

      visit new_user_session_path
      expect(page).not_to have_content("Connexion avec un compte de démo")
    end
  end
end
