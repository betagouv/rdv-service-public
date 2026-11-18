RSpec.describe Agents::CaldavSyncMailer do
  describe "#sync_disabled_incompatible_server" do
    let(:agent) { create(:agent) }
    let(:mail) { described_class.with(agent:).sync_disabled_incompatible_server }

    it "tells the agent that the sync was deleted because the server is incompatible" do
      expect(mail.to).to eq([agent.email])
      expect(mail.subject).to eq("Votre synchronisation CalDAV a été supprimée")
      expect(mail.body.encoded).to include("pas compatible")
    end
  end
end
