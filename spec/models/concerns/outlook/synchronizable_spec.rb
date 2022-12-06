# frozen_string_literal: true

RSpec.describe Outlook::Synchronizable, type: :concern do
  describe "#sync_create_in_outlook_asynchronously" do
    context "agent synced with outlook" do
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:agents_rdv) { create(:agents_rdv, agent: agent) }

      it "calls Outlook::CreateEventJob" do
        allow(Outlook::CreateEventJob).to receive(:perform_later)

        expect(Outlook::CreateEventJob).to receive(:perform_later).with(agents_rdv).once

        agents_rdv.sync_create_in_outlook_asynchronously
      end
    end

    context "agent not synced with outlook" do
      let(:agent) { create(:agent) }
      let(:agents_rdv) { create(:agents_rdv, agent: agent) }

      before do
        allow(Outlook::CreateEventJob).to receive(:perform_later)

        agents_rdv.sync_create_in_outlook_asynchronously
      end

      it "does not call Outlook::CreateEventJob" do
        expect(Outlook::CreateEventJob).not_to have_received(:perform_later)
      end
    end

    context "agents_rdv already exists in outlook" do
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:agents_rdv) { create(:agents_rdv, agent: agent, outlook_id: "abc") }

      before do
        allow(Outlook::CreateEventJob).to receive(:perform_later)

        agents_rdv.sync_create_in_outlook_asynchronously
      end

      it "does not call Outlook::CreateEventJob" do
        expect(Outlook::CreateEventJob).not_to have_received(:perform_later)
      end
    end
  end

  describe "#sync_update_in_outlook_asynchronously" do
    context "exists in outlook and agent is synced" do
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:agents_rdv) { create(:agents_rdv, agent: agent, outlook_id: "abc") }

      before do
        allow(Outlook::UpdateEventJob).to receive(:perform_later)

        agents_rdv.sync_update_in_outlook_asynchronously
      end

      it "calls Outlook::UpdateEventJob" do
        expect(Outlook::UpdateEventJob).to have_received(:perform_later).with(agents_rdv)
      end
    end

    context "exists in outlook and agent is not synced" do
      let(:agent) { create(:agent) }
      let(:agents_rdv) { create(:agents_rdv, agent: agent, outlook_id: "abc") }

      before do
        allow(Outlook::UpdateEventJob).to receive(:perform_later)

        agents_rdv.sync_update_in_outlook_asynchronously
      end

      it "does not call Outlook::UpdateEventJob" do
        expect(Outlook::UpdateEventJob).not_to have_received(:perform_later)
      end
    end

    context "does not exists in outlook" do
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:agents_rdv) { create(:agents_rdv, agent: agent) }

      it "calls Outlook::CreateEventJob" do
        allow(Outlook::CreateEventJob).to receive(:perform_later)

        expect(Outlook::CreateEventJob).to receive(:perform_later).with(agents_rdv)

        agents_rdv.sync_update_in_outlook_asynchronously
      end
    end

    context "is cancelled and exists in outlook" do
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:agents_rdv) { create(:agents_rdv, agent: agent, outlook_id: "abc") }

      before do
        allow(agents_rdv.rdv).to receive(:cancelled?).and_return(true)
        allow(Outlook::DestroyEventJob).to receive(:perform_later)

        agents_rdv.sync_update_in_outlook_asynchronously
      end

      it "calls Outlook::DestroyEventJob" do
        expect(Outlook::DestroyEventJob).to have_received(:perform_later).with(agents_rdv)
      end
    end

    context "is cancelled and does not exist in outlook" do
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:agents_rdv) { create(:agents_rdv, agent: agent) }

      before do
        allow(agents_rdv.rdv).to receive(:cancelled?).and_return(true)
        allow(Outlook::DestroyEventJob).to receive(:perform_later)

        agents_rdv.sync_update_in_outlook_asynchronously
      end

      it "does not call Outlook::DestroyEventJob" do
        expect(Outlook::DestroyEventJob).not_to have_received(:perform_later)
      end
    end

    context "is soft_deleted and exists in outlook" do
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:agents_rdv) { create(:agents_rdv, agent: agent, outlook_id: "abc") }

      before do
        allow(agents_rdv.rdv).to receive(:soft_deleted?).and_return(true)
        allow(Outlook::DestroyEventJob).to receive(:perform_later)

        agents_rdv.sync_update_in_outlook_asynchronously
      end

      it "calls DestroyEventJob" do
        expect(Outlook::DestroyEventJob).to have_received(:perform_later)
      end
    end
  end

  describe "#sync_destroy_in_outlook_asynchronously" do
    context "agent synced with outlook and exists in outlook" do
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:agents_rdv) { create(:agents_rdv, agent: agent, outlook_id: "abc") }

      before do
        allow(Outlook::DestroyEventJob).to receive(:perform_later)

        agents_rdv.sync_destroy_in_outlook_asynchronously
      end

      it "calls Outlook::DestroyEventJob" do
        expect(Outlook::DestroyEventJob).to have_received(:perform_later).with(agents_rdv)
      end
    end

    context "agent not synced with outlook" do
      let(:agent) { create(:agent) }
      let(:agents_rdv) { create(:agents_rdv, agent: agent) }

      before do
        allow(Outlook::DestroyEventJob).to receive(:perform_later)

        agents_rdv.sync_destroy_in_outlook_asynchronously
      end

      it "does not call Outlook::CreateEventJob" do
        expect(Outlook::DestroyEventJob).not_to have_received(:perform_later)
      end
    end

    context "agents_rdv does not exist in outlook" do
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:agents_rdv) { create(:agents_rdv, agent: agent) }

      before do
        allow(Outlook::DestroyEventJob).to receive(:perform_later)

        agents_rdv.sync_destroy_in_outlook_asynchronously
      end

      it "does not call Outlook::CreateEventJob" do
        expect(Outlook::DestroyEventJob).not_to have_received(:perform_later)
      end
    end
  end
end
