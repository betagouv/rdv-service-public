RSpec.describe Agents::OutlookSyncMailer do
  describe "#sync_disabled" do
    let(:agent) { create(:agent) }
    let(:mail) { described_class.with(agent:, error_description: "AADSTS700082: expired").sync_disabled }

    it "tells the agent that the sync was disabled, with the error description" do
      expect(mail.to).to eq([agent.email])
      expect(mail.subject).to eq("Votre synchronisation Outlook a été désactivée")
      expect(mail.body.encoded).to include("AADSTS700082: expired")
    end
  end
end
