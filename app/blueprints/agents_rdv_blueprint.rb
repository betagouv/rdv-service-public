# frozen_string_literal: true

class AgentsRdvBlueprint < Blueprinter::Base
  identifier :id

  association :agent, blueprint: AgentBlueprint
  association :rdv, blueprint: RdvBlueprint
end
