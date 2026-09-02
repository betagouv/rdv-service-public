RSpec.describe "RdvInvitation for users" do
  let(:rdv_invitation) { create(:rdv_invitation, lieu: create(:lieu, organisation:)) }
  let(:organisation) { create(:organisation) }

  let!(:plage_ouverture) do
    create(:plage_ouverture, :weekdays, motifs: [rdv_invitation.motif], lieu: rdv_invitation.lieu, organisation:, first_day: 1.week.from_now)
  end
  let!(:other_plage_ouverture) do
    create(:plage_ouverture, :weekdays, motifs: [rdv_invitation.motif], lieu: rdv_invitation.lieu, organisation:, first_day: 1.week.from_now)
  end

  describe "#create_rdv" do
    it "cannot be abused to create multiple rdvs for a single invitation" do
      expect do
        get rdv_invitations_create_rdv_path(rdv_invitation.token, starts_at: plage_ouverture.starts_at)
      end.to change(Rdv, :count).by(1)

      expect do
        get rdv_invitations_create_rdv_path(rdv_invitation.token, starts_at: other_plage_ouverture.starts_at)
      end.not_to change(Rdv, :count)
    end
  end
end
