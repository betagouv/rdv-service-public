# frozen_string_literal: true

class CreneauBlueprint < Blueprinter::Base
  fields :starts_at, :ends_at

  association :lieu, blueprint: LieuBlueprint
  association :motif, blueprint: MotifBlueprint
  association :agent, blueprint: AgentBlueprint
end
