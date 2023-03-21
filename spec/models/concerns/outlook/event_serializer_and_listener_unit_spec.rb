# frozen_string_literal: true

# Ce fichier teste que le bon nombre de jobs est envoyé pour différentes transactions
RSpec.describe Outlook::EventSerializerAndListener do
  context "when the agent is not connected to outlook" do
    let(:agent) { create(:agent, microsoft_graph_token: nil) }

    describe "when a rdv is created, updated and deleted" do
      it "doesn't enqueue a sync job" do
        expect(Outlook::SyncEventJob).not_to receive(:perform_later)
        rdv = create(:rdv, agents: [agent])

        rdv.update!(starts_at: rdv.starts_at + 1.hour)

        rdv.destroy
      end
    end
  end

  context "when the agent is connected to outlook" do
    let(:agent) { create(:agent, microsoft_graph_token: "token") }

    describe "when a rdv is created, updated and deleted" do
      it "queues a sync job for each change" do
        allow(Outlook::SyncEventJob).to receive(:perform_later)

        rdv = create(:rdv, agents: [agent])

        expect(Outlook::SyncEventJob).to have_received(:perform_later)

        rdv.update!(starts_at: rdv.starts_at + 1.hour)
        expect(Outlook::SyncEventJob).to have_received(:perform_later).twice

        rdv.destroy
        expect(Outlook::SyncEventJob).to have_received(:perform_later).thrice
      end
    end

    describe "when a user participation is created, updated and deleted" do
      let!(:rdv) { create(:rdv, agents: [agent]) }

      it "queues a sync job for each change" do
        allow(Outlook::SyncEventJob).to receive(:perform_later)
        participation = create(:rdvs_user, rdv: rdv)

        expect(Outlook::SyncEventJob).to have_received(:perform_later)

        participation.update!(status: RdvsUser::CANCELLED_STATUSES.first)
        expect(Outlook::SyncEventJob).to have_received(:perform_later).twice

        participation.destroy
        expect(Outlook::SyncEventJob).to have_received(:perform_later).thrice
      end
    end

    describe "when an agent participation is created and then deleted" do
      let!(:rdv) { create(:rdv) }

      it "queues a sync job for each change" do
        allow(Outlook::SyncEventJob).to receive(:perform_later)

        agent_participation = create(:agents_rdv, agent: agent, rdv: rdv)
        expect(Outlook::SyncEventJob).to have_received(:perform_later)

        agent_participation.destroy
        expect(Outlook::SyncEventJob).to have_received(:perform_later).twice
      end
    end

    describe "complex transactions" do
      describe "when the user participation and the rdv are updated" do
        let!(:rdv) { create(:rdv, agents: [agent]) }

        it "enqueues a single job after the transaction is committed" do
          allow(Outlook::SyncEventJob).to receive(:perform_later)

          ActiveRecord::Base.transaction do
            rdv.update!(starts_at: rdv.starts_at + 1.hour)
            create(:rdvs_user, rdv: rdv)
            expect(Outlook::SyncEventJob).not_to have_received(:perform_later)
          end

          expect(Outlook::SyncEventJob).to have_received(:perform_later).once
        end
      end
    end
  end
end
