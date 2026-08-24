RSpec.describe "Agents can send an invitation to a rdv" do
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:organisation) { create(:organisation) }

  let(:rdv_invitation) { create(:rdv_invitation, motif:, lieu:, user:, inviting_agent: agent) }

  let(:motif) { create(:motif, organisation:) }
  let(:lieu) { create(:lieu, organisation:) }
  let(:user) { create(:user, organisations: [organisation]) }

  before do
    login_as agent, scope: :agent
    visit new_admin_organisation_rdv_invitation_path(organisation, motif_id: motif.id, lieu_id: lieu.id, user_id: user.id)
  end

  context "when the user doesn't have an email address" do
    let(:user) { create(:user, email: nil, organisations: [organisation]) }

    it "shows an error message" do
      click_on "Envoyer l'invitation"
      expect(page).to have_content "ne peut donc pas recevoir d'invitation"
      expect(RdvInvitation.count).to eq 0
    end
  end

  context "when inviting a proche" do
    let(:user) { create(:user, :relative, organisations: [organisation], responsible: responsable) }
    let(:responsable) { create(:user) }

    it "sends the email to the responsable" do
      click_on "Envoyer l'invitation"
      expect(page).to have_content "Vous avez invité"
      expect(RdvInvitation.last).to have_attributes(user_id: user.id)
      perform_enqueued_jobs

      expect(ActionMailer::Base.deliveries.last.to).to eq([responsable.email])
    end
  end
end
