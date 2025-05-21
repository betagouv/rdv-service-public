RSpec.describe "Agent can login" do
  it "updates last_sign_in_at attribute" do
    agent = create(:agent, password: "c0rrecThorse!", last_sign_in_at: 2.weeks.ago)
    visit new_agent_session_path
    fill_in "Adresse email", with: agent.email
    fill_in "Mot de passe", with: "c0rrecThorse!"

    # On utilise 10 secondes car la spec est parfois lente en CI et devient flaky
    expect { click_on "Se connecter" }.to change { agent.reload.last_sign_in_at }
      .from(be_within(10.seconds).of(2.weeks.ago))
      .to(be_within(10.seconds).of(Time.zone.now))
  end

  context "when the agent's password is too weak" do
    let(:agent) do
      build(:agent, password: "tropfaible").tap do |a|
        a.save(validate: false)
      end
    end

    it "expire le mot de passe et redirige vers la page pour en définir un nouveau" do
      previous_encrypted_password = agent.reload.encrypted_password
      visit new_agent_session_path
      fill_in "Adresse email", with: agent.email
      fill_in "Mot de passe", with: "tropfaible"
      click_on "Se connecter"
      expect(page).to have_content("nous vous demandons de changer votre mot de passe")
      expect(agent.reload.encrypted_password).not_to eq(previous_encrypted_password) # vérifie que le mot de passe a été modifié
      fill_in "Mot de passe", with: "tropfaible2"
      click_on "Enregistrer"
      # expect(page.status_code).to eq 422 # je ne sais pas trop pourquoi devise renvoie une 422 ici
      expect(page).to have_content("Pour assurer la sécurité de votre compte, votre mot de passe doit faire au moins 12 caractères")
      fill_in "Mot de passe", with: ENV["SEED_PASSWORD"]
      click_on "Enregistrer"
      expect(page).to have_content("Votre mot de passe a été édité avec succès, votre connexion est désormais active")
      expect(page).to have_content("Bienvenue !")
    end
  end
end
