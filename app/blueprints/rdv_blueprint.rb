class RdvBlueprint < Blueprinter::Base
  identifier :id

  fields :status, :location, :duration_in_min, :starts_at

  association :organisation, blueprint: OrganisationBlueprint
  association :motif, blueprint: MotifBlueprint
  association :users, blueprint: UserBlueprint
  association :agents, blueprint: AgentBlueprint
end
