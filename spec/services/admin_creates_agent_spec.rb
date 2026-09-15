RSpec.describe AdminCreatesAgent do
  context "when inviting an agent that doesn't have any services" do
    let(:agent) do
      create(:agent, organisations: [])
    end
    let(:service1) { create(:service) }
    let(:service2) { create(:service) }
    let(:organisation) do
      create(:organisation)
    end
    let(:admin) do
      create(:agent, admin_role_in_organisations: [organisation])
    end

    it "adds the services to the agent" do
      described_class.new(
        agent_params: { email: agent.email, service_ids: [service1.id, service2.id] },
        current_agent: admin,
        organisations: [organisation],
        access_level: :basic
      ).call

      expect(agent.reload.services).to contain_exactly(service1, service2)
      expect(agent.organisations).to eq [organisation]
    end
  end

  context "when inviting a new agent as admin of an organisation with a lot of RDVs" do
    before { stub_const("AgentSensitiveAccountCalculator::SENSITIVE_RDV_THRESHOLD", 2) }

    let(:organisation) { create(:organisation) }
    let(:admin) { create(:agent, admin_role_in_organisations: [organisation]) }

    it "marque immédiatement le nouvel agent comme sensible, sans attendre le job quotidien" do
      create_list(:rdv, 3, organisation: organisation)

      agent = described_class.new(
        agent_params: { email: "new-agent@example.com", service_ids: [] },
        current_agent: admin,
        organisations: [organisation],
        access_level: :admin
      ).call

      expect(agent.reload.sensitive_account).to be true
    end
  end

  context "when the agent already has a pending invitation for this organisation" do
    subject(:service) do
      described_class.new(
        agent_params: { email: existing_agent.email, service_ids: [] },
        current_agent: admin,
        organisations: [organisation],
        access_level: :basic
      )
    end

    let(:organisation) { create(:organisation) }
    let(:admin) { create(:agent, admin_role_in_organisations: [organisation]) }
    let!(:existing_agent) do
      create(:agent, :not_confirmed, basic_role_in_organisations: [organisation], invitation_accepted_at: nil)
    end

    it "does not add a new role and exposes the conflicting organisation" do
      agent = service.call

      expect(agent).to be_invalid
      expect(service.pending_invitation_conflict_organisation).to eq(organisation)
    end
  end
end
