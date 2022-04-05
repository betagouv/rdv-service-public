# frozen_string_literal: true

class RdvBlueprint < Blueprinter::Base
  identifier :id

  fields :uuid, :status, :starts_at, :ends_at, :duration_in_min, :address, :context, :cancelled_at,
         :max_participants_count, :users_count, :name, :collectif, :created_by

  association :organisation, blueprint: OrganisationBlueprint
  association :motif, blueprint: MotifBlueprint
  association :users, blueprint: UserBlueprint
  association :agents, blueprint: AgentBlueprint
  association :lieu, blueprint: LieuBlueprint
end
