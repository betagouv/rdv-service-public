class RdvBlueprint < Blueprinter::Base
  identifier :id

  fields :uuid, :status, :starts_at, :ends_at, :duration_in_min, :address, :context, :cancelled_at,
         :max_participants_count, :users_count, :name, :collectif, :created_by_type, :created_by_id, :created_at,
         :visio_url

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

  field :url_for_agents do |rdv, _options|
    Rails.application.routes.url_helpers.agents_rdv_url(rdv, host: rdv.domain.host_name)
  end

  # On permet des associations optionnelles, mais on les charge toutes si le paramètre `include` n'est pas utilisé
  def self.conditional_association(association_name, blueprint_class)
    field(association_name, if: ->(_field_name, _rdv, options) { !options["include"].is_a?(Array) || association_name.to_s.in?(options["include"]) }) do |rdv, _options|
      associated_object = rdv.public_send(association_name)
      if associated_object
        blueprint_class.render_as_hash(associated_object)
      end
    end
  end

  conditional_association(:organisation, OrganisationBlueprint)
  conditional_association(:motif, MotifBlueprint)

  # DEPRECATED : Nous laissons l'association `:users` le temps que le 92, 26, 62, 64, et data-insertion mettent à jours leur système.
  conditional_association(:users, UserBlueprint)
  conditional_association(:participations, ParticipationBlueprint)
  conditional_association(:agents, AgentBlueprint)
  conditional_association(:lieu, LieuBlueprint)
end
