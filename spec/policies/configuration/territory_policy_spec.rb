# frozen_string_literal: true

describe Configuration::TerritoryPolicy, type: :policy do
  describe "show?" do
    it "returns false with agent without admin access to this territory" do
      territory = create(:territory)
      agent = create(:agent, role_in_territories: [])
      agent_territorial_context = AgentTerritorialContext.new(agent, territory)
      expect(described_class.new(agent_territorial_context, territory).show?).to be false
    end

    it "returns true with agent with admin access to this territory" do
      territory = create(:territory)
      agent = create(:agent, role_in_territories: [territory])
      agent_territorial_context = AgentTerritorialContext.new(agent, territory)
      expect(described_class.new(agent_territorial_context, territory).show?).to be true
    end
  end

  describe "display_sms_configuration?" do
    it "returns false with agent without admin access to this territory" do
      territory = create(:territory, has_own_sms_provider: true)
      agent = create(:agent, role_in_territories: [])
      agent_territorial_context = AgentTerritorialContext.new(agent, territory)
      expect(described_class.new(agent_territorial_context, territory).display_sms_configuration?).to be false
    end

    it "returns false when territory hasnt own sms provider" do
      territory = create(:territory, has_own_sms_provider: false)
      agent = create(:agent, role_in_territories: [])
      agent_territorial_context = AgentTerritorialContext.new(agent, territory)
      expect(described_class.new(agent_territorial_context, territory).display_sms_configuration?).to be false
    end

    it "returns true with agent with admin access to this territory" do
      territory = create(:territory, has_own_sms_provider: true)
      agent = create(:agent, role_in_territories: [territory])
      agent_territorial_context = AgentTerritorialContext.new(agent, territory)
      expect(described_class.new(agent_territorial_context, territory).display_sms_configuration?).to be true
    end
  end

  describe "display_user_fields_configuration?" do
    it "returns false with agent without admin access to this territory" do
      territory = create(:territory)
      agent = create(:agent, role_in_territories: [])
      agent_territorial_context = AgentTerritorialContext.new(agent, territory)
      expect(described_class.new(agent_territorial_context, territory).display_user_fields_configuration?).to be false
    end

    it "returns true with agent with admin access to this territory" do
      territory = create(:territory)
      agent = create(:agent, role_in_territories: [territory])
      agent_territorial_context = AgentTerritorialContext.new(agent, territory)
      expect(described_class.new(agent_territorial_context, territory).display_user_fields_configuration?).to be true
    end
  end
end
