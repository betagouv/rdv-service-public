RSpec.describe Rdv::Updatable, type: :concern do
  before do
    stub_netsize_ok
    allow(Devise.token_generator).to receive(:generate).and_return("12345678")
  end

  let(:agent) { create(:agent, rdv_notifications_level: "all") }
  let(:rdv) { create(:rdv, agents: [agent]) }
  let(:rdv_co) { create(:rdv, :collectif, users: [user_co1, user_co2], agents: [agent]) }
  let(:user_co1) { create(:user) }
  let(:user_co2) { create(:user) }
  let(:user) { rdv.users.first }

  describe "#update_and_notify" do
    it "updates the Rdv" do
      expect { rdv.update_and_notify(agent, status: "noshow") }.to change { rdv.reload.status }.to("noshow")
    end

    it "updates the updated_at attribute" do
      expect { rdv.update_and_notify(agent, status: "noshow") }.to change { rdv.reload.updated_at }
    end

    it "returns a success" do
      expect(rdv.update_and_notify(agent, status: "noshow")).to eq(true)
    end

    %w[excused revoked noshow].each do |status|
      context "when the status changed and is now #{status}" do
        it "updates the cancelled_at attribute" do
          expect { rdv.update_and_notify(agent, status: status) }.to change { rdv.reload.cancelled_at }.from(nil)
        end
      end
    end

    %w[unknown seen].each do |status|
      context "when the status changed and is now #{status}" do
        before { rdv.update!(cancelled_at: 1.day.ago, status: "noshow") }

        it "sets the cancelled_at attribute to nil" do
          expect { rdv.update_and_notify(agent, status: status) }.to change { rdv.reload.cancelled_at }.to(nil)
        end
      end
    end

    it "returns a failure when the Rdv can't be updated" do
      expect(rdv.update_and_notify(agent, ends_at: nil)).to eq(false)
    end

    describe "clear the file_attentes" do
      it "destroy all file_attentes" do
        create(:file_attente, rdv: rdv)
        expect { rdv.update_and_notify(agent, status: "excused") }.to change { rdv.reload.file_attentes }.to([])
      end
    end

    describe "sends relevant notifications" do
      it "notifies agent when rdv is cancelled (excused)" do
        rdv.update_and_notify(agent, status: "excused")
        expect_notifications_sent_for(rdv, user, :rdv_cancelled)
        expect_notifications_sent_for(rdv, agent, :rdv_cancelled)
      end

      it "notifies agent and users when rdv is cancelled (revoked) for collective rdv" do
        rdv_co.update_and_notify(agent, status: "revoked")
        expect_notifications_sent_for(rdv_co, user_co1, :rdv_cancelled)
        expect_notifications_sent_for(rdv_co, user_co2, :rdv_cancelled)
        expect_notifications_sent_for(rdv_co, agent, :rdv_cancelled)
      end

      it "doesnt notify already cancelled participations" do
        rdv_co.participations.where(user: user_co1).first.update!(status: "excused")
        rdv_co.participations.reload
        rdv_co.update_and_notify(agent, status: "revoked")
        expect_no_notifications_for_user(user_co1)
        expect_notifications_sent_for(rdv_co, user_co2, :rdv_cancelled)
        expect_notifications_sent_for(rdv_co, agent, :rdv_cancelled)
      end

      it "does not notify when status does not change" do
        rdv.reload
        rdv.update!(status: "unknown")
        rdv.update_and_notify(agent, status: "unknown")
        expect_no_notifications
      end

      it "notifies when date changes" do
        rdv.update_and_notify(agent, starts_at: 2.days.from_now)
        expect_notifications_sent_for(rdv, user, :rdv_updated)
        expect_notifications_sent_for(rdv, agent, :rdv_updated)
      end

      it "notifies when date changes for collective rdv" do
        rdv_co.update_and_notify(agent, starts_at: 2.days.from_now)
        expect_notifications_sent_for(rdv_co, user_co1, :rdv_updated)
        expect_notifications_sent_for(rdv_co, user_co2, :rdv_updated)
        expect_notifications_sent_for(rdv_co, agent, :rdv_updated)
      end

      it "does not notify when date does not change" do
        rdv.reload
        rdv.update_and_notify(agent, starts_at: rdv.starts_at)
        expect_no_notifications
      end

      it "does not notify when date does not change for collective rdv" do
        rdv_co.reload
        rdv_co.update_and_notify(agent, starts_at: rdv_co.starts_at)
        expect_no_notifications
      end

      it "does not notify when other attributes change" do
        rdv.reload
        rdv.update_and_notify(agent, context: "some context")
        expect_no_notifications
      end

      it "does not notify when other attributes change for collective rdv" do
        rdv_co.reload
        rdv_co.update_and_notify(agent, context: "some context")
        expect_no_notifications
      end
    end

    it "call Notifiers::RdvCreated when reloaded status from cancelled status" do
      rdv.update!(status: "excused", cancelled_at: Time.zone.parse("12/1/2020 12:56"))
      rdv.update_and_notify(agent, status: "unknown")
      expect_notifications_sent_for(rdv, user, :rdv_created)
      expect_notifications_sent_for(rdv, agent, :rdv_created)
    end

    it "call Notifiers::RdvCreated when reloaded status from cancelled status for collective rdv" do
      rdv_co.update!(status: "revoked", cancelled_at: Time.zone.parse("12/1/2020 12:56"))
      rdv_co.update_and_notify(agent, status: "unknown")
      expect_notifications_sent_for(rdv_co, user_co1, :rdv_created)
      expect_notifications_sent_for(rdv_co, user_co2, :rdv_created)
      expect_notifications_sent_for(rdv_co, agent, :rdv_created)
    end

    describe "triggers webhook" do
      let!(:webhook_endpoint) { create(:webhook_endpoint, organisation: organisation, subscriptions: ["rdv"]) }
      let!(:organisation) { create(:organisation, rdvs: [rdv]) }

      it "sends a webhook" do
        rdv.reload
        expect(WebhookJob).to receive(:perform_later)
        rdv.update_and_notify(agent, status: "noshow")
      end
    end

    describe "for a rdv collectif" do
      let(:attributes) do
        {
          participations_attributes: {
            0 => { user_id: user_staying.id, send_lifecycle_notifications: 1, id: rdv.participations.find_by(user_id: user_staying.id).id, _destroy: false },
            1 => { user_id: user_removed.id, send_lifecycle_notifications: 1, id: rdv.participations.find_by(user_id: user_removed.id).id, _destroy: true  },
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

      it "notifies the new participant, and the one that is removed" do
        rdv.update_and_notify(agent, attributes)
        expect_notifications_sent_for(rdv, user_added, :rdv_created)
        expect_notifications_sent_for(rdv, user_removed, :rdv_cancelled)
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
      rdv.notify!(agent, [])

      expect_notifications_sent_for(rdv, user, :rdv_updated)
      expect_notifications_sent_for(rdv, agent, :rdv_updated)
    end

    it "calls lieu_updated_notifier with lieu changes for collective rdv" do
      lieu = create(:lieu, availability: "enabled")
      autre_lieu = create(:lieu, availability: "enabled")
      rdv_co.update!(lieu: lieu)
      rdv_co.reload
      rdv_co.update_and_notify(agent, lieu: autre_lieu)
      expect_notifications_sent_for(rdv_co, user_co1, :rdv_updated)
      expect_notifications_sent_for(rdv_co, user_co2, :rdv_updated)
      expect_notifications_sent_for(rdv_co, agent, :rdv_updated)
    end
  end

  describe "#lieu_changed?" do
    context "with single_use lieu" do
      it "returns true when single_use lieu name is updated" do
        lieu = create(:lieu, availability: "single_use", name: "nom")
        rdv.update!(lieu: lieu)
        rdv.reload
        rdv.update(lieu_attributes: { name: "autre nom", id: lieu.id })
        expect(rdv.lieu_changed?).to be(true)
      end

      it "returns true when single_use lieu adress is updated" do
        lieu = create(:lieu, availability: "single_use", address: "2 place de la gare, Paris, 75016")
        rdv.update!(lieu: lieu)
        rdv.reload
        rdv.update(lieu_attributes: { address: "1 place de l'arbre, Paris, 75016", id: lieu.id })
        expect(rdv.lieu_changed?).to be(true)
      end
    end

    context "with enabled lieu" do
      it "returns true when lieu changes to lieu" do
        lieu = create(:lieu, availability: "enabled")
        autre_lieu = create(:lieu, availability: "enabled")
        rdv.update!(lieu: lieu)
        rdv.reload
        rdv.update(lieu: autre_lieu)
        expect(rdv.lieu_changed?).to be(true)
      end

      it "returns false when lieu doesnt change" do
        lieu = create(:lieu, availability: "enabled")
        rdv.update!(lieu: lieu)
        rdv.reload
        rdv.update(context: "context")
        expect(rdv.lieu_changed?).to be(false)
      end
    end

    it "returns true when lieu changes to single_use lieu" do
      lieu = create(:lieu, availability: "enabled")
      autre_lieu = create(:lieu, availability: "single_use")
      rdv.update!(lieu: lieu)
      rdv.reload
      rdv.update(lieu: autre_lieu)
      expect(rdv.lieu_changed?).to be(true)
    end

    it "returns false when lieu is nil" do
      rdv = create(:rdv, :by_phone, lieu: nil)
      rdv.reload
      expect(rdv.lieu_changed?).to be(false)
    end
  end

  describe "#change_participation_statuses on RDV.status change for collective rdv" do
    let(:rdv_co) { create(:rdv, :collectif, agents: [agent]) }
    let!(:participation1) { create(:participation, rdv: rdv_co) }
    let!(:participation2) { create(:participation, rdv: rdv_co) }
    let!(:participation_excused) { create(:participation, rdv: rdv_co, status: "excused") }
    let!(:participation_noshow) { create(:participation, rdv: rdv_co, status: "noshow") }

    context "when the status changed and is now seen" do
      it "updates participations statuses" do
        rdv_co.update_and_notify(agent, status: "seen")
        rdv_co.reload
        expect(participation1.reload.status).to eq("seen")
        expect(participation2.reload.status).to eq("seen")
        expect(participation_excused.reload.status).to eq("excused")
        expect(participation_noshow.reload.status).to eq("noshow")
      end
    end

    context "when the status changed and is now revoked" do
      it "updates participations statuses" do
        rdv_co.update_and_notify(agent, status: "revoked")
        rdv_co.reload
        expect(participation1.reload.status).to eq("revoked")
        expect(participation2.reload.status).to eq("revoked")
        expect(participation_excused.reload.status).to eq("excused")
      end
    end

    context "when the status changed and is now unknown (reset)" do
      it "updates (reset to unknown) all participations statuses" do
        rdv_co.update!(status: "revoked")
        rdv_co.update_and_notify(agent, status: "unknown")
        expect(rdv_co.participations.reload.map(&:status)).to all(include("unknown"))
      end
    end

    context "when the status changed and is now noshow" do
      it "doesnt update rdv and participations statuses" do
        rdv_co.update_and_notify(agent, status: "noshow")
        expect(rdv_co).not_to be_valid
        expect(rdv_co.reload.status).to eq("unknown")
        expect(participation1.reload.status).to eq("unknown")
        expect(participation2.reload.status).to eq("unknown")
      end
    end

    context "when the status changed and is now excused" do
      it "doesnt update rdv and participations statuses" do
        rdv_co.update_and_notify(agent, status: "excused")
        expect(rdv_co).not_to be_valid
        expect(rdv_co.reload.status).to eq("unknown")
        expect(participation1.reload.status).to eq("unknown")
        expect(participation2.reload.status).to eq("unknown")
      end
    end
  end

  describe "#change_participation_statuses on RDV.status change (individual rdvs)" do
    let(:rdv) { create(:rdv, agents: [agent]) }
    let!(:participation1) { create(:participation, rdv: rdv) }
    let!(:participation2) { create(:participation, rdv: rdv) }
    let!(:participation_excused) { create(:participation, rdv: rdv) }
    let!(:participation_noshow) { create(:participation, rdv: rdv) }

    before do
      participation_excused.update!(status: "excused")
      participation_noshow.update!(status: "noshow")
    end

    context "when the status changed and is now seen" do
      it "updates statuses" do
        rdv.update_and_notify(agent, status: "seen")
        rdv.reload
        expect(rdv.status).to eq("seen")
        expect(participation1.reload.status).to eq("seen")
        expect(participation2.reload.status).to eq("seen")
      end
    end

    context "when the status changed and is now revoked" do
      it "updates statuses" do
        rdv.update_and_notify(agent, status: "revoked")
        rdv.reload
        expect(rdv.status).to eq("revoked")
        expect(participation1.reload.status).to eq("revoked")
        expect(participation2.reload.status).to eq("revoked")
      end
    end

    context "when the status changed and is now noshow" do
      it "updates statuses" do
        rdv.update_and_notify(agent, status: "noshow")
        rdv.reload
        expect(rdv.status).to eq("noshow")
        expect(participation1.reload.status).to eq("noshow")
        expect(participation2.reload.status).to eq("noshow")
      end
    end

    context "when the status changed and is now excused" do
      it "updates statuses" do
        rdv.update_and_notify(agent, status: "excused")
        rdv.reload
        expect(rdv.status).to eq("excused")
        expect(participation1.reload.status).to eq("excused")
        expect(participation2.reload.status).to eq("excused")
      end
    end

    context "when the status changed and is now unknown (reset)" do
      it "updates (reset to unknown) all participations statuses" do
        rdv.update!(status: "revoked")
        rdv.update_and_notify(agent, status: "unknown")
        expect(rdv.participations.reload.map(&:status)).to all(include("unknown"))
      end
    end
  end
end
