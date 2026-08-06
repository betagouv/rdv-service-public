RSpec.describe Rdv::Updatable, type: :concern do
  before do
    stub_netsize_ok
    allow(Devise.token_generator).to receive(:generate).and_return("12345678")
  end

  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, rdv_notifications_level: "all") }
  let(:rdv) { create(:rdv, agents: [agent], organisation:) }
  let(:motif) { create(:motif, :collectif, organisation:) }
  let(:rdv_co) { create(:rdv, motif:, users: [user_co1, user_co2], agents: [agent], organisation:) }
  let(:user_co1) { create(:user) }
  let(:user_co2) { create(:user) }
  let(:user) { rdv.users.first }

  describe "#update_and_notify" do
    it "updates the Rdv" do
      # TODO: remove status changes in this file
      expect { rdv.update_and_notify(agent, status: "noshow") }.to change { rdv.reload.status }.to("noshow")
    end

    it "updates the updated_at attribute" do
      expect { rdv.update_and_notify(agent, status: "noshow") }.to change { rdv.reload.updated_at }
    end

    it "returns a success" do
      expect(rdv.update_and_notify(agent, status: "noshow")).to be_truthy
    end

    it "returns a failure when the Rdv can't be updated" do
      expect(rdv.update_and_notify(agent, ends_at: nil)).to be_falsey
    end

    describe "sends relevant notifications" do
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

      it "notifies when visio_url_custom is set on an existing collective visio rdv" do
        motif_visio_co = create(:motif, :collectif, location_type: :visio, organisation:)
        rdv_visio_co = create(:rdv, motif: motif_visio_co, users: [user_co1, user_co2], agents: [agent], organisation:, lieu: nil)
        rdv_visio_co.reload
        rdv_visio_co.update_and_notify(agent, visio_url_custom: "https://teams.live.com/somemeeting")
        expect_notifications_sent_for(rdv_visio_co, user_co1, :rdv_updated)
        expect_notifications_sent_for(rdv_visio_co, user_co2, :rdv_updated)
        expect_notifications_sent_for(rdv_visio_co, agent, :rdv_updated)
      end

      it "notifies when visio_url_custom changes to a new value for collective visio rdv" do
        motif_visio_co = create(:motif, :collectif, location_type: :visio, organisation:)
        rdv_visio_co = create(:rdv, motif: motif_visio_co, users: [user_co1, user_co2], agents: [agent], organisation:, lieu: nil, visio_url_custom: "https://teams.live.com/originalmeeting")
        rdv_visio_co.reload
        rdv_visio_co.update_and_notify(agent, visio_url_custom: "https://teams.live.com/newmeeting")
        expect_notifications_sent_for(rdv_visio_co, user_co1, :rdv_updated)
        expect_notifications_sent_for(rdv_visio_co, user_co2, :rdv_updated)
        expect_notifications_sent_for(rdv_visio_co, agent, :rdv_updated)
      end
    end

    describe "triggers webhook" do
      let!(:webhook_endpoint) { create(:webhook_endpoint, organisation: organisation, subscriptions: ["rdv"]) }

      it "sends a webhook" do
        rdv.reload
        expect do
          rdv.update_and_notify(agent, status: "noshow")
        end.to have_enqueued_job(WebhookJob).with(record: rdv, action: :updated, webhook_endpoint_id: webhook_endpoint.id)
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
      let(:rdv) { create(:rdv, agents: [agent], motif: motif, users: [user_staying, user_removed], organisation:).reload }
      let(:motif) { create(:motif, :collectif, organisation:) }
      let(:user_staying) { create(:user, first_name: "Stay") }
      let(:user_added) { create(:user, first_name: "Add") }
      let(:user_removed) { create(:user, first_name: "Remove") }

      it "notifies the new participant, and the one that is removed" do
        rdv.update_and_notify(agent, attributes)
        expect_notifications_sent_for(rdv, user_added, :rdv_created)
        expect_notifications_sent_for(rdv, user_removed, :rdv_cancelled)
      end

      context "quand un des usager qu'on ajoute est déjà inscrit comme participant au rdv" do
        let(:rdv) { create(:rdv, agents: [agent], motif: motif, users: [user_staying, user_added], organisation:).reload }

        let(:attributes) do
          {
            participations_attributes: {
              0 => { user_id: user_staying.id, send_lifecycle_notifications: 1, id: rdv.participations.find_by(user_id: user_staying.id).id, _destroy: false },
              1 => { user_id: user_added.id, send_lifecycle_notifications: 1 },
            },
          }
        end

        it "garde l'usager et n'envoie pas de notification supplémentaire" do
          rdv.update_and_notify(agent, attributes)
          expect_no_notifications
        end
      end
    end
  end

  describe "notifications" do
    let(:autre_lieu) { create(:lieu, availability: "enabled") }
    let(:lieu) { create(:lieu, availability: "enabled") }

    it "calls lieu_updated_notifier with lieu changes" do
      rdv.update!(lieu: lieu)
      rdv.reload

      rdv.update_and_notify(agent, lieu: autre_lieu)

      expect_notifications_sent_for(rdv, user, :rdv_updated)
      expect_notifications_sent_for(rdv, agent, :rdv_updated)
    end

    it "calls lieu_updated_notifier with lieu changes for collective rdv" do
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
        expect(rdv.send(:lieu_changed?)).to be(true)
      end

      it "returns true when single_use lieu adress is updated" do
        lieu = create(:lieu, availability: "single_use", address: "2 place de la gare, Paris, 75016")
        rdv.update!(lieu: lieu)
        rdv.reload
        rdv.update(lieu_attributes: { address: "1 place de l'arbre, Paris, 75016", id: lieu.id })
        expect(rdv.send(:lieu_changed?)).to be(true)
      end
    end

    context "with enabled lieu" do
      it "returns true when lieu changes to lieu" do
        lieu = create(:lieu, availability: "enabled")
        autre_lieu = create(:lieu, availability: "enabled")
        rdv.update!(lieu: lieu)
        rdv.reload
        rdv.update(lieu: autre_lieu)
        expect(rdv.send(:lieu_changed?)).to be(true)
      end

      it "returns false when lieu doesnt change" do
        lieu = create(:lieu, availability: "enabled")
        rdv.update!(lieu: lieu)
        rdv.reload
        rdv.update(context: "context")
        expect(rdv.send(:lieu_changed?)).to be(false)
      end
    end

    it "returns true when lieu changes to single_use lieu" do
      lieu = create(:lieu, availability: "enabled")
      autre_lieu = create(:lieu, availability: "single_use")
      rdv.update!(lieu: lieu)
      rdv.reload
      rdv.update(lieu: autre_lieu)
      expect(rdv.send(:lieu_changed?)).to be(true)
    end

    it "returns false when lieu is nil" do
      rdv = create(:rdv, :by_phone, lieu: nil)
      rdv.reload
      expect(rdv.send(:lieu_changed?)).to be(false)
    end
  end
end
