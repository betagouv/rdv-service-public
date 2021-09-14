# frozen_string_literal: true

class RdvBlueprint < Blueprinter::Base
  identifier :id

  fields :uuid, :status, :duration_in_min, :starts_at, :address, :context

  association :organisation, blueprint: OrganisationBlueprint
  association :motif, blueprint: MotifBlueprint
  association :users, blueprint: UserBlueprint
  association :agents, blueprint: AgentBlueprint
  association :lieu, blueprint: LieuBlueprint
end
