RSpec.describe "Prise de rendez-vous par invitation", js: true do
  let(:motif) { create(:motif, organisation:) }
  let(:organisation) { create(:organisation) }
  let(:lieu) { create(:lieu, organisation:) }
  let!(:plage_ouverture) do
    create(:plage_ouverture, :weekdays, motifs: [motif], lieu:, organisation:, first_day: Time.zone.today)
  end

  let(:rdv_invitation) { create(:rdv_invitation, motif:, lieu:) }

  it "connecte l'usager après la prise de rendez-vou" do
    visit rdv_invitations_path(rdv_invitation_token: rdv_invitation.token)

    click_on "8:00", match: :first

    expect(page).to have_content "coucou"
  end
end
