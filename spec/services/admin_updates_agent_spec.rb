RSpec.describe AdminUpdatesAgent do
  context "lors du changement de rôle d'un agent vers admin dans une organisation avec beaucoup de RDVs" do
    before { stub_const("AgentSensitiveAccountCalculator::SENSITIVE_RDV_THRESHOLD", 2) }

    let(:organisation) { create(:organisation) }
    let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:inviting_agent) { create(:agent, admin_role_in_organisations: [organisation]) }

    it "marque immédiatement l'agent comme sensible, sans attendre le job quotidien" do
      create_list(:rdv, 3, organisation: organisation)

      described_class.new(
        agent: agent,
        organisation: organisation,
        new_access_level: :admin,
        agent_params: {},
        inviting_agent: inviting_agent
      ).call

      expect(agent.reload.sensitive_account).to be true
    end
  end
end
