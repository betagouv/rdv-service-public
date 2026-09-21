RSpec.describe "Annuler une invitation" do
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:rdv_invitation) { create(:rdv_invitation, inviting_agent: agent, motif:, user:) }
  let(:organisation) { create(:organisation) }
  let(:motif) { create(:motif, organisation:) }
  let(:user) { create(:user, organisations: [organisation]) }

  before { login_as agent, scope: :agent }

  it "permet d'annuler une invitation" do
    visit admin_organisation_rdv_invitation_path(organisation, rdv_invitation)

    click_on "Résilier l'invitation"

    expect(page).to have_content "Cette invitation a été résiliée. L'usager ne pourra pas prendre ce rendez-vous."

    expect(rdv_invitation.reload).to be_cancelled
  end
end
