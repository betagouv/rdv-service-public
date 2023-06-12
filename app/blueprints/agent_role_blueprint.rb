# frozen_string_literal: true

class AgentRoleBlueprint < Blueprinter::Base
  identifier :id

  # TODO: remove :level field after rdv-i migration
  fields :level, :access_level
  association :organisation, blueprint: OrganisationBlueprint
  association :agent, blueprint: AgentBlueprint
end
