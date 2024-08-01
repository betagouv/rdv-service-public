RSpec.describe Configuration::WebhookEndpointPolicy, type: :policy do
  %i[new? create? edit? update? destroy?].each do |action|
    describe "##{action}" do
      it "returns false with agent without admin access to this territory" do
        territory = create(:territory)
        agent = create(:agent, role_in_territories: [])
        organisation = create(:organisation, territory:)
        webhook_endpoint = build(:webhook_endpoint, organisation:)
        agent_territorial_context = AgentTerritorialContext.new(agent, territory)
        expect(described_class.new(agent_territorial_context, webhook_endpoint).send(action)).to be false
      end

      it "returns true with agent with admin access to this territory" do
        territory = create(:territory)
        agent = create(:agent, role_in_territories: [territory])
        organisation = create(:organisation, territory:)
        webhook_endpoint = build(:webhook_endpoint, organisation:)
        agent_territorial_context = AgentTerritorialContext.new(agent, territory)
        expect(described_class.new(agent_territorial_context, webhook_endpoint).send(action)).to be true
      end
    end
  end
end
