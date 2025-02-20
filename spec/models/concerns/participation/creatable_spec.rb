RSpec.describe Participation::Creatable, type: :concern do
  before do
    stub_netsize_ok
    allow(Devise.token_generator).to receive(:generate).and_return("12345")
  end

  describe "Participation create" do
    let(:agent) { create :agent }
    let(:user) { create :user }
    let(:user3) { create :user }
    let!(:organisation) { create(:organisation) }
    let(:relative) do
      create(:user, :relative, :without_devise_email, responsible: user, first_name: "Petit", last_name: "Bébé")
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
        expect(participation1.participation_token).to be_nil
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
