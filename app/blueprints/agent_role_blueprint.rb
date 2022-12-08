# frozen_string_literal: true

class AgentRoleBlueprint < Blueprinter::Base
  fields :level

  association :organisation, blueprint: OrganisationBlueprint
  association :agent, blueprint: AgentBlueprint
end
