class RdvBlueprint < Blueprinter::Base
  identifier :id

  fields :uuid, :status, :starts_at, :ends_at, :duration_in_min, :address, :context, :cancelled_at,
         :max_participants_count, :users_count, :name, :collectif, :created_by

  association :organisation, blueprint: OrganisationBlueprint
  association :motif, blueprint: MotifBlueprint
  # DEPRECATED : Nous laissons l'association `:users` le temps que le 92, 26, 62, 64, et data-insertion mettent à jours leur système.
  association :users, blueprint: UserBlueprint
  # DEPRECATED : On garde l'ancien nom des participations le temps que le 92, 26, 62, 64, et data-insertion mettent à jours leur système.
  association :participations, blueprint: ParticipationBlueprint, name: :rdvs_users
  association :participations, blueprint: ParticipationBlueprint
  association :agents, blueprint: AgentBlueprint
  association :lieu, blueprint: LieuBlueprint
end
