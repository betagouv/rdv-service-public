class RdvBlueprint < Blueprinter::Base
  identifier :id

  fields :uuid, :status, :starts_at, :ends_at, :duration_in_min, :address, :context, :cancelled_at,
         :max_participants_count, :users_count, :name, :collectif, :created_by_type, :created_by_id

  # Retrocompatibilité avec l'ancien format de l'API pour created_by
  field :created_by do |rdv, _options|
    created_by_type_map = {
      "Agent" => "agent",
      "User" => "user",
      "Prescripteur" => "prescripteur",
      "FileAttente" => "file_attente",
    }

    created_by_type_map[rdv.created_by_type]
  end

  association :organisation, blueprint: OrganisationBlueprint
  association :motif, blueprint: MotifBlueprint
  # DEPRECATED : Nous laissons l'association `:users` le temps que le 92, 26, 62, 64, et data-insertion mettent à jours leur système.
  association :users, blueprint: UserBlueprint
  association :participations, blueprint: ParticipationBlueprint
  association :agents, blueprint: AgentBlueprint
  association :lieu, blueprint: LieuBlueprint

  view :rdv_insertion do
    association :users, blueprint: UserBlueprint, view: :rdv_insertion
  end
end
