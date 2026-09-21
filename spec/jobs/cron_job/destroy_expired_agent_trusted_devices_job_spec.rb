RSpec.describe CronJob::DestroyExpiredAgentTrustedDevicesJob, type: :job do
  describe "#perform" do
    it "supprime les appareils de confiance expirés" do
      agent = create(:agent)
      expired = nil
      travel_to(8.days.ago) { expired = AgentTrustedDevice.remember!(agent) }
      expired_device = AgentTrustedDevice.find_by!(token_digest: AgentTrustedDevice.digest(expired))

      described_class.perform_now

      expect(AgentTrustedDevice.exists?(expired_device.id)).to be false
    end

    it "conserve les appareils de confiance encore valides" do
      agent = create(:agent)
      raw_token = AgentTrustedDevice.remember!(agent)
      active_device = AgentTrustedDevice.find_by!(token_digest: AgentTrustedDevice.digest(raw_token))

      described_class.perform_now

      expect(AgentTrustedDevice.exists?(active_device.id)).to be true
    end
  end
end
