RSpec.describe "Agents can change their email" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], password: "CorrectH0rse!") }
  let!(:admin_agent) { create(:agent, admin_role_in_organisations: [organisation]) } # Organisation needs at least one admin

  before do
    login_as(agent, scope: :agent)
    visit edit_agent_registration_path
  end

  it "checks for password confirmation, length and complexity" do
    new_email = "nouvel-email@example.com"
    fill_in "Email", with: new_email
    fill_in "Mot de passe actuel", with: "CorrectH0rse!"

    expect { click_button "Modifier" }.not_to change { agent.reload.email }

    expect(page).to have_content("Votre compte a bien été mis à jour mais nous devons vérifier votre nouvelle adresse email")
    perform_enqueued_jobs
    open_email(new_email)
    current_email.click_link("Confirmer mon compte")

    expect(page).to have_content("Votre compte a été validé")
    expect(agent.reload.email).to eq(new_email)
  end
end
