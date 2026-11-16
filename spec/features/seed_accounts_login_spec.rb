RSpec.describe "Connexion en un clic avec les comptes seeds" do
  let(:seed_agent) { SeedAccounts.agents.find { _1.slug == :martine } }
  let(:seed_user) { SeedAccounts.users.find { _1.slug == :patricia_duroy } }

  context "en review app (IS_REVIEW_APP=true)" do
    stub_env_with(IS_REVIEW_APP: "true", DB_SEEDS_USERS_AND_AGENTS_PASSWORD: "Rdvservicepublictest1!")

    it "sur la page de connexion agent, un clic poste le formulaire et connecte l'agent" do
      agent = create(:agent, email: seed_agent.email, password: "Rdvservicepublictest1!", last_sign_in_at: 2.weeks.ago)

      visit new_agent_session_path
      expect(page).to have_button("[DEV] Utiliser un des comptes par défaut…")
      expect(page).to have_field("agent[email]", with: seed_agent.email, type: :hidden, visible: :all)
      expect(page).to have_field("agent[password]", with: "Rdvservicepublictest1!", type: :hidden, visible: :all)

      expect { click_on seed_agent.label }.to change { agent.reload.last_sign_in_at }
        .from(be_within(10.seconds).of(2.weeks.ago))
    end

    it "sur la page de connexion usager, un clic poste la demande de code de connexion" do
      create(:user, email: seed_user.email)

      visit new_user_session_path
      expect(page).to have_button("[DEV] Utiliser un des comptes par défaut…")
      expect(page).to have_field("login_code_request_form[email]", with: seed_user.email, type: :hidden, visible: :all)

      click_on seed_user.label
      expect(page).to have_content("code à 6 chiffres")
      expect(LoginCode.last.email).to eq(seed_user.email)
    end
  end

  context "hors dev et review app" do
    it "n'affiche pas le bloc des comptes seeds" do
      visit new_agent_session_path
      expect(page).not_to have_button("[DEV] Utiliser un des comptes par défaut…")

      visit new_user_session_path
      expect(page).not_to have_button("[DEV] Utiliser un des comptes par défaut…")
    end
  end
end
