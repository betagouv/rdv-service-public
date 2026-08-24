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

    context "when the user is a relative" do
      let(:user) { create(:user, :relative, organisations: [organisation]) }

      it "isn't supported" do
        expect(rdv_invitation).not_to be_valid
      end
    end
  end

  describe "#create_rdv_and_notify" do
    let!(:plage_ouverture) do
      create(:plage_ouverture, :weekdays, motifs: [motif], lieu:, organisation:, first_day: Time.zone.today)
    end

    describe "niveau de notification" do
      context "pour un motif normal" do
        let(:motif) { create(:motif, :visible_and_notified, organisation:) }

        it "crée une participation avec des notifications" do
          rdv_invitation.create_rdv_and_notify(starts_at: plage_ouverture.starts_at)

          expect(rdv_invitation.reload.rdv.participations.first).to have_attributes(
            send_lifecycle_notifications: true,
            send_reminder_notification: true
          )
        end
      end

      context "pour un motif non-notifié" do
        let(:motif) { create(:motif, :visible_and_not_notified, organisation:) }

        it "crée une participation sans notifications" do
          rdv_invitation.create_rdv_and_notify(starts_at: plage_ouverture.starts_at)

          expect(rdv_invitation.reload.rdv.participations.first).to have_attributes(
            send_lifecycle_notifications: false,
            send_reminder_notification: false
          )
        end
      end
    end
  end
end
