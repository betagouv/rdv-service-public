RSpec.describe RdvInvitation do
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:organisation) { create(:organisation) }

  let(:rdv_invitation) { build(:rdv_invitation, motif:, lieu:, user:, inviting_agent: agent) }

  let(:motif) { create(:motif, organisation:) }
  let(:lieu) { create(:lieu, organisation:) }
  let(:user) { create(:user, organisations: [organisation]) }

  describe "validations" do
    context "when the motif is collectif" do
      let(:motif) { create(:motif, :collectif, organisation:) }

      it "isn't supported" do
        expect(rdv_invitation).not_to be_valid
      end
    end

    context "when the motif is ANTS" do
      let(:motif_category) { create(:motif_category, :passeport) }
      let(:motif) { create(:motif, motif_category:, organisation:) }

      it "isn't supported" do
        expect(rdv_invitation).not_to be_valid
      end
    end

    context "when the motif is phone" do
      let(:motif) { create(:motif, organisation:, location_type: :phone) }
      let(:user) { create(:user, organisations: [organisation], phone_number: nil) }

      it "requires the user to have a phone number" do
        expect(rdv_invitation).not_to be_valid
      end
    end
  end
end
