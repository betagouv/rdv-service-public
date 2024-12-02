RSpec.describe "Agent can accept invitation" do
  let(:agent) { create(:agent) }

  context "when password is secure" do
    it "accepts the invitation" do
      agent.deliver_invitation
      visit accept_agent_invitation_path(invitation_token: agent.raw_invitation_token)
      fill_in "Prénom", with: "John"
      fill_in "Nom", with: "Doe"
      fill_in "Mot de passe", with: "c0rrecThorse!"

      expect { click_on "Enregistrer" }.to change { agent.reload.encrypted_password }
      expect(page).to have_content("Votre mot de passe a été enregistré et votre compte est activé.")
    end
  end

  context "when password is not secure" do
    it "shows a warning and advises to change the password" do
      agent.deliver_invitation
      visit accept_agent_invitation_path(invitation_token: agent.raw_invitation_token)
      fill_in "Prénom", with: "John"
      fill_in "Nom", with: "Doe"
      fill_in "Mot de passe", with: "tropfaible"

      click_on "Enregistrer"
      expect(page).to have_content("Pour assurer la sécurité de votre compte, votre mot de passe doit faire au moins 12 caractères")
    end
  end
end
