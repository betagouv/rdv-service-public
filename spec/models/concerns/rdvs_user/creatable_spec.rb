# frozen_string_literal: true

RSpec.describe RdvsUser::Creatable, type: :concern do
  before do
    stub_netsize_ok
    allow(Devise.token_generator).to receive(:generate).and_return("12345")
  end

  describe "RdvsUser create" do
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
      let(:rdv_user1) { build(:rdvs_user, rdv: rdv, user: user) }

      it "sends a webhook" do
        rdv.reload
        expect(WebhookJob).to receive(:perform_later)
        rdv_user1.create_and_notify(user)
      end
    end

    describe "with notifications" do
      let(:rdv_user1) { build(:rdvs_user, rdv: rdv, user: user) }
      let(:rdv_user_relative) { build(:rdvs_user, rdv: rdv, user: relative) }

      it "for self (user)" do
        rdv_user1.create_and_notify(user)
        expect_notifications_sent_for(rdv, user, :rdv_created)
        expect_notifications_sent_for(rdv, agent, :rdv_created)
        expect(rdv.reload.rdvs_users).to eq([rdv_user1])
        expect(rdv_user1.rdv_user_token).to eq("12345")
      end

      it "for a relative with existing participations" do
        rdv_user1.save!
        rdv_user_relative.create_and_notify(user)
        expect_notifications_sent_for(rdv, user, :rdv_created)
        expect_notifications_sent_for(rdv, agent, :rdv_created)
        expect(rdv.reload.rdvs_users).to eq([rdv_user_relative])
        expect(rdv_user1.rdv_user_token).to eq(nil)
      end
    end

    describe "without notifications" do
      let(:rdv_user_with_lifecycle_disabled) { build(:rdvs_user, rdv: rdv, send_lifecycle_notifications: false, user: user3) }
      let(:rdv_user1) { build(:rdvs_user, rdv: rdv, user: user) }
      let(:rdv_user_relative) { build(:rdvs_user, rdv: rdv, user: relative, send_lifecycle_notifications: false) }

      it "for self (user)" do
        rdv_user_with_lifecycle_disabled.create_and_notify(user3)
        expect_no_notifications_for(rdv, user, :rdv_created)
        expect_notifications_sent_for(rdv, agent, :rdv_created)
        expect(rdv.reload.rdvs_users).to eq([rdv_user_with_lifecycle_disabled])
      end

      it "for a relative" do
        rdv_user_relative.create_and_notify(user)
        expect_no_notifications_for(rdv, user, :rdv_created)
        expect_notifications_sent_for(rdv, agent, :rdv_created)
        expect(rdv.reload.rdvs_users).to eq([rdv_user_relative])
      end
    end
  end
end
