RSpec.describe "En cas d'invitation annulée" do
  let(:rdv_invitation) { create(:rdv_invitation, cancelled: true) }

  it "indique que l'invitation est annulée, et affiche les informations de contact de l'organisation" do
    visit rdv_invitations_path(rdv_invitation.token)

    expect(page).to have_content("Cette invitation a été résiliée par l'organisation qui vous l'a envoyé.")
  end
end
