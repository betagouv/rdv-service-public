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
end
