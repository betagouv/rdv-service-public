RSpec.describe "Agent resets his password spec" do
  let!(:agent) { create(:agent) }

  around { |example| perform_enqueued_jobs { example.run } }

  it "works by sending a reset email" do
    visit new_agent_password_path
    expect(page).to have_content("Mot de passe oublié ?")
    expect(page).to have_link("Se connecter")

    fill_in "agent_email", with: agent.email
    expect { click_on "Envoyer" }.to change { emails_sent_to(agent.email).size }.by(1)

    open_email(agent.email)
    current_email.click_link("Changer")
    expect(page).to have_content("Définir mon mot de passe")

    fill_in "password", with: "q1w2e3r4t5y6"
    expect { click_on "Enregistrer" }.not_to change { agent.reload.encrypted_password }
    expect(page).to have_content("Ce mot de passe fait partie d'une liste de mots de passe fréquemment utilisés")

    fill_in "password", with: "correct H0rse battery! staple"
    expect { click_on "Enregistrer" }.to change { agent.reload.encrypted_password }
    expect(page).to have_content("Votre mot de passe a été édité avec succès")
    expect(page).to have_link("Vos organisations")
  end

  it "works when using the user's password reset form" do
    visit new_user_password_path
    expect(page).to have_content("Mot de passe oublié ?")
    expect(page).to have_link("Se connecter")

    fill_in "user_email", with: agent.email
    expect { click_on "Envoyer" }.to change { emails_sent_to(agent.email).size }.by(1)

    open_email(agent.email)
    current_email.click_link("Changer")
    expect(page).to have_content("Définir mon mot de passe")
    fill_in "password", with: "correct H0rse battery! staple"
    expect { click_on "Enregistrer" }.to change { agent.reload.encrypted_password }
    expect(page).to have_content("Votre mot de passe a été édité avec succès")
    expect(page).to have_link("Vos organisations")
  end
end
