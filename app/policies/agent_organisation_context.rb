# frozen_string_literal: true

# TODO: supprimer ce context, nous devrions pouvoir utiliser l'organisation de l'objet sur lequel on vérifier l'accès
class AgentOrganisationContext
  attr_reader :agent, :organisation, :agent_role

  delegate :can_access_others_planning?, to: :agent_role, allow_nil: true

  def initialize(agent, organisation)
    @agent = agent
    @organisation = organisation
    @agent_role = AgentRole.find_by(agent: @agent, organisation: @organisation)
  end
end
