RSpec.describe Agents::OutlookSyncMailer do
  describe "#sync_disabled" do
    let(:agent) { create(:agent) }
    let(:mail) { described_class.with(agent:, error_description: "AADSTS700082: expired", error_uri: "https://login.microsoftonline.com/error?code=700082").sync_disabled }

    it "tells the agent that the sync was disabled, with the error description" do
      expect(mail.to).to eq([agent.email])
      expect(mail.subject).to eq("Votre synchronisation Outlook a été désactivée")
      expect(mail.body.encoded).to include("AADSTS700082: expired")
      expect(mail.body.encoded).to include("https://login.microsoftonline.com/error?code=700082")
    end
  end
end
