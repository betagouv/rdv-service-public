# frozen_string_literal: true

RSpec.describe Rdv::Updatable, type: :concern do
  before { stub_netsize_ok }

  let(:agent) { create(:agent) }
  let!(:rdv) { create(:rdv, agents: [agent]) }

  describe "#update_with_notifs" do
    it "updates the Rdv" do
      expect { rdv.update_with_notifs(agent, status: "noshow") }.to change { rdv.reload.status }.to("noshow")
    end

    it "updates the updated_at attribute" do
      expect { rdv.update_with_notifs(agent, status: "noshow") }.to change { rdv.reload.updated_at }
    end

    it "returns a success" do
      expect(rdv.update_with_notifs(agent, status: "noshow")).to be_success
    end

    %w[excused revoked noshow].each do |status|
      context "when the status changed and is now #{status}" do
        it "updates the cancelled_at attribute" do
          expect { rdv.update_with_notifs(agent, status: status) }.to change { rdv.reload.cancelled_at }.from(nil)
        end
      end
    end

    %w[unknown waiting seen].each do |status|
      context "when the status changed and is now #{status}" do
        before { rdv.update!(cancelled_at: 1.day.ago, status: "noshow") }

        it "sets the cancelled_at attribute to nil" do
          expect { rdv.update_with_notifs(agent, status: status) }.to change { rdv.reload.cancelled_at }.to(nil)
        end
      end
    end

    it "returns a failure when the Rdv can't be updated" do
      expect(rdv.update_with_notifs(agent, ends_at: nil)).not_to be_success
    end

    describe "clear the file_attentes" do
      it "destroy all file_attentes" do
        create(:file_attente, rdv: rdv)
        expect { rdv.update_with_notifs(agent, status: "excused") }.to change { rdv.reload.file_attentes }.to([])
      end
    end

    describe "sends relevant notifications" do
      it "notifies when rdv cancelled" do
        expect(Notifiers::RdvCancelled).to receive(:perform_with).with(rdv, agent)
        rdv.update_with_notifs(agent, status: "excused")
      end

      it "does not notify when status does not change" do
        rdv.update!(status: "waiting")
        expect(Notifiers::RdvCancelled).not_to receive(:perform_with)
        rdv.update_with_notifs(agent, status: "waiting")
      end

      it "notifies when date changes" do
        expect(Notifiers::RdvUpdated).to receive(:perform_with).with(rdv, agent)
        rdv.update_with_notifs(agent, starts_at: 1.day.from_now)
      end

      it "does not notify when date does not change" do
        rdv.reload
        expect(Notifiers::RdvUpdated).not_to receive(:perform_with)
        rdv.update_with_notifs(agent, starts_at: rdv.starts_at)
      end

      it "does not notify when other attributes change" do
        rdv.reload
        expect(Notifiers::RdvCancelled).not_to receive(:perform_with)
        expect(Notifiers::RdvUpdated).not_to receive(:perform_with)
        rdv.update_with_notifs(agent, context: "some context")
      end
    end

    it "call Notifiers::RdvCreated when reloaded status from cancelled status" do
      rdv.update!(status: "excused", cancelled_at: Time.zone.parse("12/1/2020 12:56"))
      expect(Notifiers::RdvCreated).to receive(:perform_with)
      rdv.update_with_notifs(agent, status: "unknown")
    end

    describe "for a rdv collectif" do
      let(:attributes) do
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
      let(:motif) { create(:motif, :collectif) }
      let(:user_staying) { create(:user, first_name: "Stay") }
      let(:user_added) { create(:user, first_name: "Add") }
      let(:user_removed) { create(:user, first_name: "Remove") }
      let(:sms_sender_double) { instance_double(SmsSender) }

      it "notifies the new participant, and the one that is removed" do
        expect(SmsSender).to receive(:new).and_return(sms_sender_double).twice
        expect(sms_sender_double).to receive(:perform).twice
        rdv.update_with_notifs(agent, attributes)

        expect(ActionMailer::Base.deliveries.count).to eq 2

        added_email = ActionMailer::Base.deliveries.first
        expect(added_email.subject).to include "RDV confirmé"

        removed_email = ActionMailer::Base.deliveries.last
        expect(removed_email.subject).to include "RDV annulé"
      end
    end
  end

  describe "#rdv_status_reloaded_from_cancelled?" do
    Rdv::CANCELLED_STATUSES.each do |cancelled_status|
      it "true when rdv status from #{cancelled_status} to unknown" do
        rdv.update!(status: cancelled_status)
        rdv.update!(status: "unknown")
        expect(rdv.rdv_status_reloaded_from_cancelled?).to eq(true)
      end
    end

    Rdv::NOT_CANCELLED_STATUSES.each do |not_cancelled_status|
      # From unknown to unkown permet de tester le cas où il n'y a pas de changement sur le status
      it "false when rdv status from #{not_cancelled_status} to unknown" do
        rdv.update!(status: not_cancelled_status)
        rdv.update!(status: "unknown")
        expect(rdv.rdv_status_reloaded_from_cancelled?).to eq(false)
      end
    end
  end

  describe "#notify!" do
    it "calls lieu_updated_notifier with lieu changes" do
      lieu = create(:lieu, availability: "enabled")
      autre_lieu = create(:lieu, availability: "enabled")
      rdv.update!(lieu: lieu)
      rdv.reload
      rdv.update(lieu: autre_lieu)
      expect(Notifiers::RdvUpdated).to receive(:perform_with)
      rdv.notify!(agent, [])
    end
  end

  describe "#lieu_change?" do
    context "with single_use lieu" do
      it "returns true when single_use lieu name is updated" do
        lieu = create(:lieu, availability: "single_use", name: "nom")
        rdv.update!(lieu: lieu)
        rdv.reload
        rdv.update(lieu_attributes: { name: "autre nom", id: lieu.id })
        expect(rdv.lieu_change?).to be(true)
      end

      it "returns true when single_use lieu adress is updated" do
        lieu = create(:lieu, availability: "single_use", address: "2 place de la gare")
        rdv.update!(lieu: lieu)
        rdv.reload
        rdv.update(lieu_attributes: { address: "derrière l'arbre", id: lieu.id })
        expect(rdv.lieu_change?).to be(true)
      end
    end

    context "with enabled lieu" do
      it "returns true when lieu changes to lieu" do
        lieu = create(:lieu, availability: "enabled")
        autre_lieu = create(:lieu, availability: "enabled")
        rdv.update!(lieu: lieu)
        rdv.reload
        rdv.update(lieu: autre_lieu)
        expect(rdv.lieu_change?).to be(true)
      end

      it "returns false when lieu doesnt change" do
        lieu = create(:lieu, availability: "enabled")
        rdv.update!(lieu: lieu)
        rdv.reload
        rdv.update(context: "context")
        expect(rdv.lieu_change?).to be(false)
      end
    end

    it "returns true when lieu changes to single_use lieu" do
      lieu = create(:lieu, availability: "enabled")
      autre_lieu = create(:lieu, availability: "single_use")
      rdv.update!(lieu: lieu)
      rdv.reload
      rdv.update(lieu: autre_lieu)
      expect(rdv.lieu_change?).to be(true)
    end

    it "returns false when lieu is nil" do
      rdv = create(:rdv, :by_phone, lieu: nil)
      rdv.reload
      expect(rdv.lieu_change?).to be(false)
    end
  end
end
