class AgentRoleBlueprint < Blueprinter::Base
  identifier :id

  fields :access_level
  association :organisation, blueprint: OrganisationBlueprint
  association :agent, blueprint: AgentBlueprint
end
