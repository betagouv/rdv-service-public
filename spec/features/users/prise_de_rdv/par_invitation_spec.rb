RSpec.describe "Prise de rendez-vous par invitation" do
  let(:motif) { create(:motif, organisation:) }
  let(:organisation) { create(:organisation) }
  let(:lieu) { create(:lieu, organisation:) }
  let!(:plage_ouverture) do
    create(:plage_ouverture, :weekdays, motifs: [motif], lieu:, organisation:, first_day: Time.zone.today)
  end

  let(:rdv_invitation) { create(:rdv_invitation, motif:, lieu:) }

  before { visit rdv_invitations_path(rdv_invitation_token: rdv_invitation.token) }

  context "quand l'invitation n'a pas encore été utilisée" do
    it "connecte l'usager après la prise de rendez-vous", js: true do
      click_on "8:00", match: :first

      expect(page).to have_content "Votre rendez vous a été confirmé."

      rdv = rdv_invitation.reload.rdv
      expect(rdv).to have_attributes(
        organisation:, motif:, lieu:,
        agents: [plage_ouverture.agent],
        status: "unknown",
        users: [rdv_invitation.user]
      )
    end
  end

  context "quand un rendez-vous a déjà été pris avec cette invitation" do
    let(:user) { create(:user) }
    let(:rdv_invitation) { create(:rdv_invitation, motif:, lieu:, user:, rdv: create(:rdv, motif:, lieu:, users: [user], organisation:)) }

    it "redirige vers la page du rendez-vous, avec l'authentification avec les trois premières lettres" do
      expect(page).to have_content "Pour sécuriser l’accès à vos données, veuillez entrer les 3 premières lettres de votre nom de famille."
    end
  end
end
