# frozen_string_literal: true

describe RdvUpdater, type: :service do
  describe "#update" do
    describe "return value" do
      it "true when everything is ok" do
        agent = create(:agent)
        lieu = create(:lieu)
        rdv = create(:rdv, lieu: lieu, agents: [agent], status: "waiting")
        rdv.reload
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
        expect(Notifiers::RdvUpdated).to receive(:perform_with).with(rdv, agent)
        described_class.update(agent, rdv, rdv_params)
      end

      it "does not notify when date does not change" do
        agent = create(:agent)
        lieu = create(:lieu)
        rdv = create(:rdv, lieu: lieu, agents: [agent], status: "waiting")
        rdv.reload
        rdv_params = { starts_at: rdv.starts_at }
        expect(Notifiers::RdvUpdated).not_to receive(:perform_with)
        described_class.update(agent, rdv, rdv_params)
      end

      it "does not notify when other attributes change" do
        agent = create(:agent)
        lieu = create(:lieu)
        rdv = create(:rdv, lieu: lieu, agents: [agent], status: "waiting")
        rdv.reload
        rdv_params = { context: "some context" }
        expect(Notifiers::RdvCancelled).not_to receive(:perform_with)
        expect(Notifiers::RdvUpdated).not_to receive(:perform_with)
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

    it "call Notifiers::RdvCreated when reloaded status from cancelled status" do
      agent = build(:agent)
      rdv = create(:rdv, agents: [agent], status: "excused", cancelled_at: Time.zone.parse("12/1/2020 12:56"))

      expect(Notifiers::RdvCreated).to receive(:perform_with)
      described_class.update(agent, rdv, { status: "unknown" })
    end
  end

  describe "for a rdv collectif" do
    let(:rdv_params) do
      {
        rdvs_users_attributes: {
          0 => { user_id: user_staying.id, send_lifecycle_notifications: 1, id: rdv.rdvs_users.find_by(user_id: user_staying.id).id, _destroy: false },
          1 => { user_id: user_removed.id, send_lifecycle_notifications: 1, id: rdv.rdvs_users.find_by(user_id: user_removed.id).id, _destroy: true  },
          2 => { user_id: user_added.id, send_lifecycle_notifications: 1 },
        },
      }
    end
    # The reload makes sure we have the proper .previous_changes
    let(:rdv) { create(:rdv, agents: [agent], motif: motif, users: [user_staying, user_removed]).reload }
    let(:agent) { create :agent }
    let(:motif) { create(:motif, :collectif) }

    let(:user_staying) { create(:user, first_name: "Stay") }
    let(:user_added) { create(:user, first_name: "Add") }
    let(:user_removed) { create(:user, first_name: "Remove") }

    let(:token) { "some-token" }
    let(:sms_sender_double) { instance_double(SmsSender) }

    it "notifies the new participant, and the one that is removed" do
      expect(SmsSender).to receive(:new).and_return(sms_sender_double).twice
      expect(sms_sender_double).to receive(:perform).twice
      described_class.update(agent, rdv, rdv_params)
      expect(ActionMailer::Base.deliveries.count).to eq 2

      added_email = ActionMailer::Base.deliveries.first
      expect(added_email.subject).to include "RDV confirmé"

      removed_email = ActionMailer::Base.deliveries.last
      expect(removed_email.subject).to include "RDV annulé"
    end
  end

  describe "#rdv_status_reloaded_from_cancelled?" do
    Rdv::CANCELLED_STATUSES.each do |cancelled_status|
      it "true when rdv status from #{cancelled_status} to unknown" do
        rdv = create(:rdv, status: cancelled_status)
        rdv.update!(status: "unknown")
        expect(described_class.rdv_status_reloaded_from_cancelled?(rdv)).to eq(true)
      end
    end

    Rdv::NOT_CANCELLED_STATUSES.each do |not_cancelled_status|
      # From unknown to unkown permet de tester le cas où il n'y a pas de changement sur le status
      it "false when rdv status from #{not_cancelled_status} to unknown" do
        rdv = create(:rdv, status: not_cancelled_status)
        rdv.update!(status: "unknown")
        expect(described_class.rdv_status_reloaded_from_cancelled?(rdv)).to eq(false)
      end
    end
  end

  describe "#notify!" do
    it "calls lieu_updated_notifier with lieu changes" do
      author = create(:agent)
      lieu = create(:lieu, availability: "enabled")
      autre_lieu = create(:lieu, availability: "enabled")
      rdv = create(:rdv, lieu: lieu)
      rdv.reload
      rdv.update(lieu: autre_lieu)
      expect(Notifiers::RdvUpdated).to receive(:perform_with)
      described_class.notify!(author, rdv, [])
    end
  end

  describe "#lieu_change?" do
    context "with single_use lieu" do
      it "returns true when single_use lieu name is updated" do
        lieu = create(:lieu, availability: "single_use", name: "nom")
        rdv = create(:rdv, lieu: lieu)
        rdv.reload
        rdv.update(lieu_attributes: { name: "autre nom", id: lieu.id })
        expect(described_class.lieu_change?(rdv)).to be(true)
      end

      it "returns true when single_use lieu adress is updated" do
        lieu = create(:lieu, availability: "single_use", address: "2 place de la gare")
        rdv = create(:rdv, lieu: lieu)
        rdv.reload
        rdv.update(lieu_attributes: { address: "derrière l'arbre", id: lieu.id })
        expect(described_class.lieu_change?(rdv)).to be(true)
      end
    end

    context "with enabled lieu" do
      it "returns true when lieu changes to lieu" do
        lieu = create(:lieu, availability: "enabled")
        autre_lieu = create(:lieu, availability: "enabled")
        rdv = create(:rdv, lieu: lieu)
        rdv.reload
        rdv.update(lieu: autre_lieu)
        expect(described_class.lieu_change?(rdv)).to be(true)
      end

      it "returns false when lieu doesnt change" do
        lieu = create(:lieu, availability: "enabled")
        rdv = create(:rdv, lieu: lieu)
        rdv.reload
        rdv.update(context: "context")
        expect(described_class.lieu_change?(rdv)).to be(false)
      end
    end

    it "returns true when lieu changes to single_use lieu" do
      lieu = create(:lieu, availability: "enabled")
      autre_lieu = create(:lieu, availability: "single_use")
      rdv = create(:rdv, lieu: lieu)
      rdv.reload
      rdv.update(lieu: autre_lieu)
      expect(described_class.lieu_change?(rdv)).to be(true)
    end

    it "returns false when lieu is nil" do
      rdv = create(:rdv, :by_phone, lieu: nil)
      rdv.reload
      expect(described_class.lieu_change?(rdv)).to be(false)
    end
  end
end
