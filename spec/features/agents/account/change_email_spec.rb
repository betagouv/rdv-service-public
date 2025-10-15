RSpec.describe "Agents can change their email" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], password: "CorrectH0rse!") }
  let!(:admin_agent) { create(:agent, admin_role_in_organisations: [organisation]) } # Organisation needs at least one admin

  before do
    login_as(agent, scope: :agent)
    visit edit_agent_registration_path
  end

  it "sends confirmation email to new address, notification email to old address" do
    old_email = agent.email
    new_email = "nouvel-email@example.com"
    fill_in "Email", with: new_email
    fill_in "Mot de passe actuel", with: "CorrectH0rse!"

    expect { click_button "Enregistrer" }.not_to change { agent.reload.email }
    expect(page).to have_content("Votre compte a bien été mis à jour mais nous devons vérifier votre nouvelle adresse email")

    perform_enqueued_jobs
    notification_email = emails_sent_to(old_email).sole
    confirmation_email = emails_sent_to(new_email).sole

    # L'ancienne adresse reçoit une notification
    expect(notification_email.subject).to eq("Notification : demande de changement d’email")
    body = notification_email.text_part.body.decoded.squish
    expect(body).to include("Vous venez de demander à changer d’adresse e-mail")
    expect(body).to include("Adresse actuelle : #{old_email}")
    expect(body).to include("Nouvelle adresse : #{new_email}")

    # La nouvelle adresse reçoit le mail de confirmation
    expect do
      confirmation_email.click_link("Confirmer mon adresse email")
    end.to change { agent.reload.email }.from(old_email).to(new_email)
    expect(page).to have_content("Votre compte a été validé")
  end
end
