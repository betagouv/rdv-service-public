RSpec.describe "Connexion en un clic avec les comptes seeds" do
  let(:seed_agent_email) { "martine@demo.rdv-solidarites.fr" }
  let(:seed_user_email) { "patricia_duroy@demo.rdv-solidarites.fr" }

  context "en review app (IS_REVIEW_APP=true, domaine RDV_SOLIDARITES par défaut)" do
    stub_env_with(IS_REVIEW_APP: "true", DB_SEEDS_USERS_AND_AGENTS_PASSWORD: "Rdvservicepublictest1!")

    it "sur la page de connexion agent, un clic poste le formulaire et connecte l'agent" do
      agent = create(:agent, email: seed_agent_email, password: "Rdvservicepublictest1!", last_sign_in_at: 2.weeks.ago)

      visit new_agent_session_path
      expect(page).to have_content("Connexion avec un compte de démo")
      expect(page).to have_field("agent[email]", with: seed_agent_email, type: :hidden, visible: :all)
      expect(page).to have_field("agent[password]", with: "Rdvservicepublictest1!", type: :hidden, visible: :all)

      expect { click_on "martine" }.to change { agent.reload.last_sign_in_at }
        .from(be_within(10.seconds).of(2.weeks.ago))
    end

    it "sur la page de connexion usager, un clic poste la demande de code de connexion" do
      create(:user, email: seed_user_email)

      visit new_user_session_path
      expect(page).to have_content("Connexion avec un compte de démo")
      expect(page).to have_field("login_code_request_form[email]", with: seed_user_email, type: :hidden, visible: :all)

      click_on "patricia_duroy"
      expect(page).to have_content("code à 6 chiffres")
      expect(LoginCode.last.email).to eq(seed_user_email)
    end

    it "n'affiche que les comptes du domaine courant et ceux sans domaine" do
      visit new_agent_session_path
      expect(page).to have_button("martine") # RDV_SOLIDARITES
      expect(page).to have_button("camille-clavier") # sans domain => affiché partout
      expect(page).not_to have_button("alain.mairie") # RDV_SERVICE_PUBLIC
    end
  end

  context "en review app RDV_SERVICE_PUBLIC (REVIEW_APP_DOMAIN=RDV_SERVICE_PUBLIC)" do
    stub_env_with(IS_REVIEW_APP: "true", REVIEW_APP_DOMAIN: "RDV_SERVICE_PUBLIC", DB_SEEDS_USERS_AND_AGENTS_PASSWORD: "Rdvservicepublictest1!")

    it "affiche les comptes RDV_SERVICE_PUBLIC et pas ceux de RDV_SOLIDARITES" do
      visit new_agent_session_path
      expect(page).to have_button("alain.mairie") # RDV_SERVICE_PUBLIC
      expect(page).to have_button("camille-clavier") # sans domain => affiché partout
      expect(page).not_to have_button("martine") # RDV_SOLIDARITES
    end
  end

  context "hors dev et review app" do
    it "n'affiche pas le bloc des comptes seeds" do
      visit new_agent_session_path
      expect(page).not_to have_content("Connexion avec un compte de démo")

      visit new_user_session_path
      expect(page).not_to have_content("Connexion avec un compte de démo")
    end
  end
end
