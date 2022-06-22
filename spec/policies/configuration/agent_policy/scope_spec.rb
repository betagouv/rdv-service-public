# frozen_string_literal: true

describe Configuration::AgentPolicy::Scope, type: :policy do
  it "returns agents of same territory and same organisation and same service" do
    territory = create(:territory)
    service = create(:service)
    organisation = create(:organisation, territory: territory)
    agent = create(:agent, organisations: [organisation], service: service)
    create(:agent_territorial_access_right, agent: agent, territory: territory)
    agent_from_same_terr = create(:agent, organisations: [organisation], service: service)
    create(:agent_territorial_access_right, agent: agent_from_same_terr, territory: territory)

    expect(described_class.new(AgentTerritorialContext.new(agent, territory), Agent).resolve).to match_array([agent, agent_from_same_terr])
  end

  it "returns only agents from my organisations" do
    territory = create(:territory)
    organisation = create(:organisation, territory: territory)
    other_organisation = create(:organisation, territory: territory)
    agent = create(:agent, organisations: [organisation])
    create(:agent_territorial_access_right, agent: agent, territory: territory)

    agent_from_other_orga = create(:agent, organisations: [other_organisation])
    create(:agent_territorial_access_right, agent: agent_from_other_orga, territory: territory)

    expect(described_class.new(AgentTerritorialContext.new(agent, territory), Agent).resolve).to eq([agent])
  end

  it "returns only agents from my service" do
    territory = create(:territory)
    service = create(:service)
    other_service = create(:service)

    organisation = create(:organisation, territory: territory)

    agent = create(:agent, organisations: [organisation], service: service)
    create(:agent_territorial_access_right, agent: agent, territory: territory)

    agent_from_other_service = create(:agent, organisations: [organisation], service: other_service)
    create(:agent_territorial_access_right, agent: agent_from_other_service, territory: territory)

    expect(described_class.new(AgentTerritorialContext.new(agent, territory), Agent).resolve).to eq([agent])
  end

  it "returns all agents when territory admin" do
    territory = create(:territory)
    service = create(:service)
    other_service = create(:service)

    organisation = create(:organisation, territory: territory)
    other_organisation = create(:organisation, territory: territory)

    agent = create(:agent, role_in_territories: [territory], organisations: [organisation], service: service)
    create(:agent_territorial_access_right, agent: agent, territory: territory)

    agent_from_other_service = create(:agent, organisations: [organisation], service: other_service)
    create(:agent_territorial_access_right, agent: agent_from_other_service, territory: territory)

    agent_from_other_orga = create(:agent, organisations: [other_organisation])
    create(:agent_territorial_access_right, agent: agent_from_other_orga, territory: territory)

    expect(described_class.new(AgentTerritorialContext.new(agent, territory), Agent).resolve).to match_array([agent, agent_from_other_service, agent_from_other_orga])
  end
end
