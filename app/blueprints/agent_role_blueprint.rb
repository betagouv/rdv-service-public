# frozen_string_literal: true

class AgentRoleBlueprint < Blueprinter::Base
  identifier :id

  fields :level
  association :organisation, blueprint: OrganisationBlueprint
  association :agent, blueprint: AgentBlueprint
end
