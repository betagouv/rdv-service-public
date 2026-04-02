class Agents::TerritoryCreationRequestMailerPreview < ActionMailer::Preview
  def accepted
    agent = Agent.joins(:organisations).last
    Agents::TerritoryCreationRequestMailer.accepted(agent: agent, domain_id: Domain::RDV_SERVICE_PUBLIC.id, organisation: agent.organisations.last)
  end

  def refused
    agent = Agent.joins(:territory_creation_request).last
    Agents::TerritoryCreationRequestMailer.refused(agent: agent, domain_id: Domain::RDV_SERVICE_PUBLIC.id)
  end
end
