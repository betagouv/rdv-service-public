RSpec.describe Participation::Creatable, type: :concern do
  before do
    stub_netsize_ok
  end

  describe "Participation create" do
    let(:agent) { create :agent }
    let(:user) { create :user }
    let(:user2) { create :user, :without_devise_email, notification_email: "notif@email.fr" }
    let(:user3) { create :user }
    let!(:organisation) { create(:organisation) }
    let(:relative) do
      create(:user, :relative, :without_devise_email, responsible: user, first_name: "Petit", last_name: "Bébé")
    end
    let(:relative2) do
      create(:user, :relative, :without_devise_email, responsible: user2, first_name: "Grand", last_name: "Bébé")
    end
    let(:rdv) { create :rdv, :collectif, :without_users, starts_at: Time.zone.tomorrow, agents: [agent], organisation: }

    describe "triggers webhook" do
      let!(:webhook_endpoint) { create(:webhook_endpoint, organisation: organisation, subscriptions: ["rdv"]) }
      let(:participation1) { build(:participation, rdv: rdv, user: user) }

      it "sends a webhook" do
        rdv.reload
        expect(WebhookJob).to receive(:perform_later)
        participation1.create_and_notify!(user)
      end
    end

    describe "with notifications for devise email" do
      let(:participation1) { build(:participation, rdv: rdv, user: user) }
      let(:participation_relative) { build(:participation, rdv: rdv, user: relative) }

      it "for self (user)" do
        participation1.create_and_notify!(user)
        expect_notifications_sent_for(rdv, user, :rdv_created)
        expect_notifications_sent_for(rdv, agent, :participation_created)
        expect(rdv.reload.participations).to eq([participation1])
      end

      it "for a relative with existing participations" do
        participation1.save!
        participation_relative.create_and_notify!(user)
        expect_notifications_sent_for(rdv, user, :rdv_created)
        expect_notifications_sent_for(rdv, agent, :participation_created)
        expect(rdv.reload.participations).to eq([participation_relative])
      end
    end

    describe "with notifications for a notification email" do
      let(:participation1) { build(:participation, rdv: rdv, user: user2) }
      let(:participation_relative) { build(:participation, rdv: rdv, user: relative2) }

      it "for self (user2)" do
        participation1.create_and_notify!(user2)
        expect_notifications_sent_for(rdv, user2, :rdv_created)
        expect_notifications_sent_for(rdv, agent, :participation_created)
        expect(rdv.reload.participations).to eq([participation1])
      end

      it "for a relative with existing participations" do
        participation1.save!
        participation_relative.create_and_notify!(user2)
        expect_notifications_sent_for(rdv, user2, :rdv_created)
        expect_notifications_sent_for(rdv, agent, :participation_created)
        expect(rdv.reload.participations).to eq([participation_relative])
      end
    end

    describe "without notifications" do
      let(:participation_with_lifecycle_disabled) { build(:participation, rdv: rdv, send_lifecycle_notifications: false, user: user3) }
      let(:participation1) { build(:participation, rdv: rdv, user: user) }
      let(:participation_relative) { build(:participation, rdv: rdv, user: relative, send_lifecycle_notifications: false) }

      it "for self (user)" do
        participation_with_lifecycle_disabled.create_and_notify!(user3)
        expect_no_notifications_for(rdv, user, :rdv_created)
        expect_notifications_sent_for(rdv, agent, :participation_created)
        expect(rdv.reload.participations).to eq([participation_with_lifecycle_disabled])
      end

      it "for a relative" do
        participation_relative.create_and_notify!(user)
        expect_no_notifications_for(rdv, user, :rdv_created)
        expect_notifications_sent_for(rdv, agent, :participation_created)
        expect(rdv.reload.participations).to eq([participation_relative])
      end
    end

    describe "l’usager ajouté n’appartient pas encore à l’organisation" do
      let(:participation) { build(:participation, rdv:, user:) }

      it "ajoute l’orga à l’usager" do
        expect(user.organisations).to be_empty
        participation.create_and_notify!(user)
        expect(user.organisations).to contain_exactly(organisation)
      end
    end

    describe "l’usager ajouté appartient déjà à l’organisation" do
      let!(:user) { create(:user, organisations: [organisation]) }
      let(:participation) { build(:participation, rdv:, user:) }

      it "ne ré-ajoute pas l’orga à l’usager" do
        expect(user.organisations).to contain_exactly(organisation)
        participation.create_and_notify!(user)
        expect(user.organisations).to contain_exactly(organisation)
        expect(user.organisations.count).to eq(1)
      end
    end
  end
end
