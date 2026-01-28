RSpec.describe CronJob::RefreshAgentsSensitiveAccountJob, type: :job do
  describe "#perform" do
    it "rafraîchit sensitive_account pour tous les agents" do
      # Stub le seuil pour éviter de créer beaucoup de RDVs
      stub_const("Agent::SensitiveAccountConcern::SENSITIVE_TERRITORY_RDV_THRESHOLD", 2)

      territory = create(:territory)
      organisation = create(:organisation, territory: territory)
      agent_with_sensitive_account = create(:agent, role_in_territories: [territory], sensitive_account: false)
      agent_without_sensitive_account = create(:agent, sensitive_account: true)
      create_list(:rdv, 3, organisation: organisation)

      described_class.perform_now

      expect(agent_with_sensitive_account.reload.sensitive_account).to be true
      expect(agent_without_sensitive_account.reload.sensitive_account).to be false
    end
  end
end
