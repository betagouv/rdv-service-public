class RdvBlueprint < Blueprinter::Base
  identifier :id

  fields :uuid, :status, :duration_in_min, :starts_at, :address

  association :organisation, blueprint: OrganisationBlueprint
  association :motif, blueprint: MotifBlueprint
  association :users, blueprint: UserBlueprint
  association :agents, blueprint: AgentBlueprint
end
