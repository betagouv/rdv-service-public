# Ce fichier teste que le bon nombre de jobs est envoyé pour différentes transactions
RSpec.describe Outlook::EventSerializerAndListener do
  context "when the agent is not connected to outlook" do
    let(:agent) { create(:agent, microsoft_graph_token: nil) }

    describe "when a rdv is created, updated and deleted" do
      it "doesn't enqueue a sync job" do
        expect do
          rdv = create(:rdv, agents: [agent])
          rdv.update!(starts_at: rdv.starts_at + 1.hour)
          rdv.destroy
        end.not_to have_enqueued_job(Outlook::SyncEventJob)
      end
    end
  end

  context "when the agent is connected to outlook" do
    let(:agent) { create(:agent, microsoft_graph_token: "token") }

    describe "when a rdv is created, updated and deleted" do
      it "queues a sync job for each change" do
        rdv = nil
        expect do
          rdv = create(:rdv, agents: [agent])
        end.to have_enqueued_job(Outlook::SyncEventJob)

        expect do
          rdv.update!(starts_at: rdv.starts_at + 1.hour)
        end.to have_enqueued_job(Outlook::SyncEventJob)

        expect do
          rdv.destroy
        end.to have_enqueued_job(Outlook::SyncEventJob)
      end
    end

    describe "when a user participation is created, updated and deleted" do
      let!(:rdv) { create(:rdv, agents: [agent]) }

      it "queues a sync job for each change" do
        participation = nil
        expect do
          participation = create(:participation, rdv: rdv)
        end.to have_enqueued_job(Outlook::SyncEventJob)

        expect do
          participation.update!(status: Participation::CANCELLED_STATUSES.first)
        end.to have_enqueued_job(Outlook::SyncEventJob)

        expect do
          participation.destroy
        end.to have_enqueued_job(Outlook::SyncEventJob)
      end
    end

    describe "when an agent participation is created and then deleted" do
      let!(:rdv) { create(:rdv) }

      it "queues a sync job for each change" do
        agent_participation = nil
        expect do
          agent_participation = create(:agents_rdv, agent: agent, rdv: rdv)
        end.to have_enqueued_job(Outlook::SyncEventJob)

        expect do
          agent_participation.destroy
        end.to have_enqueued_job(Outlook::SyncEventJob)
      end
    end

    describe "complex transactions" do
      describe "when the user participation and the rdv are updated" do
        let!(:rdv) { create(:rdv, agents: [agent]) }

        it "enqueues a single job after the transaction is committed" do
          expect do
            ActiveRecord::Base.transaction do
              expect do
                rdv.update!(starts_at: rdv.starts_at + 1.hour)
                create(:participation, rdv: rdv)
              end.not_to have_enqueued_job(Outlook::SyncEventJob) # Rien n'est enqueued à l'intérieur de la transaction
            end
          end.to have_enqueued_job(Outlook::SyncEventJob) # un job est enqueued quand la transaction est committed
        end
      end
    end
  end
end
