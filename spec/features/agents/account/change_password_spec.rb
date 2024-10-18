RSpec.describe "Agents can change their passwords" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], password: "Rdvservicepublic0!") }
  let!(:admin_agent) { create(:agent, admin_role_in_organisations: [organisation]) } # Organisation needs at least one admin

  before do
    login_as(agent, scope: :agent)
    visit edit_agent_registration_path
    click_link "Changer de mot de passe"
  end

  it "checks for password confirmation, length and complexity" do
    fill_in "Nouveau mot de passe", with: "unmotdepasse"
    fill_in "Confirmation du mot de passe", with: "unautremotdepasse"
    fill_in "Mot de passe actuel", with: "Rdvservicepublic0!"

    expect { click_button "Enregistrer" }.not_to change { agent.reload.encrypted_password }

    expect(page).to have_content "Le nouveau mot de passe et la confirmation ne concordent pas"

    fill_in "Nouveau mot de passe", with: "tropcourt"
    fill_in "Confirmation du mot de passe", with: "tropcourt"
    fill_in "Mot de passe actuel", with: "Rdvservicepublic0!"

    expect { click_button "Enregistrer" }.not_to change { agent.reload.encrypted_password }

    expect(page).to have_content "Pour assurer la sécurité de votre compte, votre mot de passe doit faire au moins 12 caractères"

    fill_in "Nouveau mot de passe", with: "q1w2e3r4t5y6"
    fill_in "Confirmation du mot de passe", with: "q1w2e3r4t5y6"
    fill_in "Mot de passe actuel", with: "Rdvservicepublic0!"

    expect { click_button "Enregistrer" }.not_to change { agent.reload.encrypted_password }

    expect(page).to have_content "Ce mot de passe fait partie d'une liste de mots de passe fréquemment utilisés et ne permet donc pas d'assurer la sécurité de votre compte."

    fill_in "Nouveau mot de passe", with: "correcthorsebattery"
    fill_in "Confirmation du mot de passe", with: "correcthorsebattery"
    fill_in "Mot de passe actuel", with: "Rdvservicepublic0!"

    expect { click_button "Enregistrer" }.not_to change { agent.reload.encrypted_password }

    expect(page).to have_content "Votre mot de passe doit comporter au moins un chiffre."
    expect(page).to have_content "Votre mot de passe doit comporter au moins une majuscule."
    expect(page).to have_content "Votre mot de passe doit comporter au moins un caractère spécial, par exemple un signe de ponctuation."

    fill_in "Nouveau mot de passe", with: "Correcth0rsebattery!"
    fill_in "Confirmation du mot de passe", with: "Correcth0rsebattery!"
    fill_in "Mot de passe actuel", with: "Rdvservicepublic0!"

    expect { click_button "Enregistrer" }.to change { agent.reload.encrypted_password }

    expect(page).to have_content "Votre mot de passe a été changé"
    expect(page).to have_current_path(edit_agent_registration_path)
  end
end
