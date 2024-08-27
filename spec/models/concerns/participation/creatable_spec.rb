RSpec.describe Participation::Creatable, type: :concern do
  before do
    stub_netsize_ok
    allow(Devise.token_generator).to receive(:generate).and_return("12345")
  end

  describe "Participation create" do
    let(:agent) { create :agent }
    let(:user) { create :user }
    let(:user3) { create :user }
    let(:relative) do
      create(:user, :relative, :with_no_email, responsible: user, first_name: "Petit", last_name: "Bébé")
    end
    let(:rdv) { create :rdv, :collectif, :without_users, starts_at: Time.zone.tomorrow, agents: [agent] }

    describe "triggers webhook" do
      let!(:webhook_endpoint) { create(:webhook_endpoint, organisation: organisation, subscriptions: ["rdv"]) }
      let!(:organisation) { create(:organisation, rdvs: [rdv]) }
      let(:participation1) { build(:participation, rdv: rdv, user: user) }

      it "sends a webhook" do
        rdv.reload
        expect(WebhookJob).to receive(:perform_later)
        participation1.create_and_notify!(user)
      end
    end

    describe "with notifications" do
      let(:participation1) { build(:participation, rdv: rdv, user: user) }
      let(:participation_relative) { build(:participation, rdv: rdv, user: relative) }

      it "for self (user)" do
        participation1.create_and_notify!(user)
        expect_notifications_sent_for(rdv, user, :rdv_created)
        expect_notifications_sent_for(rdv, agent, :rdv_created)
        expect(rdv.reload.participations).to eq([participation1])
        expect(participation1.participation_token).to eq("12345")
      end

      it "for a relative with existing participations" do
        participation1.save!
        participation_relative.create_and_notify!(user)
        expect_notifications_sent_for(rdv, user, :rdv_created)
        expect_notifications_sent_for(rdv, agent, :rdv_created)
        expect(rdv.reload.participations).to eq([participation_relative])
        expect(participation1.participation_token).to be(nil)
      end
    end

    describe "without notifications" do
      let(:participation_with_lifecycle_disabled) { build(:participation, rdv: rdv, send_lifecycle_notifications: false, user: user3) }
      let(:participation1) { build(:participation, rdv: rdv, user: user) }
      let(:participation_relative) { build(:participation, rdv: rdv, user: relative, send_lifecycle_notifications: false) }

      it "for self (user)" do
        participation_with_lifecycle_disabled.create_and_notify!(user3)
        expect_no_notifications_for(rdv, user, :rdv_created)
        expect_notifications_sent_for(rdv, agent, :rdv_created)
        expect(rdv.reload.participations).to eq([participation_with_lifecycle_disabled])
      end

      it "for a relative" do
        participation_relative.create_and_notify!(user)
        expect_no_notifications_for(rdv, user, :rdv_created)
        expect_notifications_sent_for(rdv, agent, :rdv_created)
        expect(rdv.reload.participations).to eq([participation_relative])
      end
    end
  end
end
