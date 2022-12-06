# frozen_string_literal: true

class ReferentAssignationBlueprint < Blueprinter::Base
  association :user, blueprint: UserBlueprint
  association :agent, blueprint: AgentBlueprint
end
