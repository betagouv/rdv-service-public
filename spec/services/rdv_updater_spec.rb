# frozen_string_literal: true

describe RdvUpdater, type: :service do
  describe "#update" do
    describe "return value" do
      it "true when everything is ok" do
        agent = build :agent
        rdv = create(:rdv, agents: [agent])
        rdv_params = {}
        expect(RdvUpdater::Result).to receive(:new).with(success: true, rdv_users_tokens_by_user_id: {})
        described_class.update(agent, rdv, rdv_params)
      end

      it "return false when update fail" do
        agent = build :agent
        rdv = create(:rdv, agents: [agent])
        rdv_params = { agents: [] }
        expect(RdvUpdater::Result).to receive(:new).with(success: false, rdv_users_tokens_by_user_id: {})
        described_class.update(agent, rdv, rdv_params)
      end
    end

    describe "clear the file_attentes" do
      it "destroy all file_attentes" do
        agent = build :agent
        rdv = create(:rdv, agents: [agent])
        create(:file_attente, rdv: rdv)
        rdv_params = { status: "excused" }
        described_class.update(agent, rdv, rdv_params)
        expect(rdv.reload.file_attentes).to be_empty
      end
    end

    describe "sends relevant notifications" do
      it "notifies when rdv cancelled" do
        agent = build :agent
        rdv = create(:rdv, agents: [agent], status: "waiting")
        rdv_params = { status: "excused" }
        expect(Notifiers::RdvCancelled).to receive(:perform_with).with(rdv, agent)
        described_class.update(agent, rdv, rdv_params)
      end

      it "does not notify when status does not change" do
        agent = build :agent
        rdv = create(:rdv, agents: [agent], status: "waiting")
        rdv_params = { status: "waiting" }
        expect(Notifiers::RdvCancelled).not_to receive(:perform_with)
        described_class.update(agent, rdv, rdv_params)
      end

      it "notifies when date changes" do
        agent = build :agent
        rdv = create(:rdv, agents: [agent], status: "waiting")
        rdv_params = { starts_at: 1.day.from_now }
        expect(Notifiers::RdvDateUpdated).to receive(:perform_with).with(rdv, agent)
        described_class.update(agent, rdv, rdv_params)
      end

      it "does not notify when date does not change" do
        agent = build :agent
        rdv = create(:rdv, agents: [agent], status: "waiting")
        rdv_params = { starts_at: rdv.starts_at }
        expect(Notifiers::RdvDateUpdated).not_to receive(:perform_with)
        described_class.update(agent, rdv, rdv_params)
      end

      it "does not notify when other attributes change" do
        agent = build :agent
        rdv = create(:rdv, agents: [agent], status: "waiting")
        rdv_params = { context: "some context" }
        expect(Notifiers::RdvCancelled).not_to receive(:perform_with)
        expect(Notifiers::RdvDateUpdated).not_to receive(:perform_with)
        described_class.update(agent, rdv, rdv_params)
      end
    end

    describe "manually touches the rdv" do
      it "force updated_at to ensure new version will be recorded" do
        now = Time.zone.local(2020, 4, 23, 12, 56)
        travel_to(now)
        previous_date = now - 3.days

        agent = build :agent
        rdv = create(:rdv, agents: [agent], updated_at: previous_date, context: "")
        rdv_params = { context: "un nouveau context" }
        described_class.update(agent, rdv, rdv_params)
        expect(rdv.reload.updated_at).to be_within(3.seconds).of now
        travel_back
      end
    end

    describe "sets and resets cancelled_at" do
      it "reset cancelled_at when status change" do
        cancelled_at = Time.zone.local(2020, 1, 12, 12, 56)
        agent = build :agent
        rdv = create(:rdv, agents: [agent], status: "noshow", cancelled_at: cancelled_at)
        rdv_params = { status: "waiting" }
        described_class.update(agent, rdv, rdv_params)
        expect(rdv.reload.cancelled_at).to eq(nil)
      end

      it "dont reset cancelled_at when no status change" do
        cancelled_at = Time.zone.local(2020, 1, 12, 12, 56)
        agent = build :agent
        rdv = create(:rdv, agents: [agent], status: "excused", cancelled_at: cancelled_at, context: "")
        rdv_params = { context: "something new" }
        described_class.update(agent, rdv, rdv_params)
        expect(rdv.reload.cancelled_at).to be_within(3.seconds).of cancelled_at
      end

      it "where status change from excused to noshow, cancelled_at should be refresh" do
        now = Time.zone.local(2020, 4, 23, 12, 56)
        travel_to(now)
        agent = build :agent
        rdv = create(:rdv, agents: [agent], status: "excused", cancelled_at: Time.zone.parse("12/1/2020 12:56"))
        described_class.update(agent, rdv, { status: "noshow" })
        expect(rdv.reload.cancelled_at).to be_within(3.seconds).of now
      end
    end
  end

  describe "for a rdv collectif" do
    let(:rdv_params) do
      {
        rdvs_users_attributes: {
          0 => { user_id: user_staying.id, send_lifecycle_notifications: 1, id: rdv.rdvs_users.find_by(user_id: user_staying.id).id, _destroy: false },
          1 => { user_id: user_removed.id, send_lifecycle_notifications: 1, id: rdv.rdvs_users.find_by(user_id: user_removed.id).id, _destroy: true  },
          2 => { user_id: user_added.id, send_lifecycle_notifications: 1 }
        }
      }
    end
    let(:rdv) { create(:rdv, agents: [agent], motif: motif, users: [user_staying, user_removed]) }
    let(:agent) { create :agent }
    let(:motif) { create(:motif, :collectif) }

    let(:user_staying) { create(:user, first_name: "Stay") }
    let(:user_added) { create(:user, first_name: "Add") }
    let(:user_removed) { create(:user, first_name: "Remove") }

    let(:token) { "some-token" }

    before do
      allow(Users::RdvMailer).to receive(:rdv_created).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
      allow(Users::RdvMailer).to receive(:rdv_cancelled).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
      allow_any_instance_of(RdvsUser).to receive(:new_raw_invitation_token).and_return(token) # rubocop:disable RSpec/AnyInstance
    end

    it "notifies the new participant, and the one that is removed" do
      expect(Users::RdvMailer).to receive(:rdv_created).once.with(rdv, user_added, token)
      expect(Users::RdvMailer).to receive(:rdv_cancelled).once.with(rdv, user_removed, nil)

      described_class.update(agent, rdv, rdv_params)
    end
  end
end
