class TeamBlueprint < Blueprinter::Base
  identifier :id

  fields :name

  association :territory, blueprint: TerritoryBlueprint
  association :agents, blueprint: AgentBlueprint
end
