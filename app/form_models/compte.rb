# Permet d'ouvrir un "compte", c'est à dire un nouveau territoire avec une organisation, et quelques infos supplémentaires
class Compte
  include ActiveModel::Model

  CATEGORIES = %w[État Département Intercommunalité Commune Région Opérateur Association Inconnu].freeze

  attr_accessor :territory, :organisation, :lieu, :agent

  def initialize(attributes, current_domain: nil, territory_creation_request: nil)
    @attributes = attributes
    @current_domain = current_domain
    @territory_creation_request = territory_creation_request
    self.territory = Territory.new(@attributes[:territory] || {})

    self.organisation = Organisation.new((@attributes[:organisation] || {}).merge(
                                           territory: territory,
                                           verticale: @current_domain&.verticale
                                         ))
    self.lieu = Lieu.new((@attributes[:lieu] || {}).merge(
                           organisation: organisation,
                           name: organisation.name,
                           availability: :enabled
                         ))
  end

  def save!
    ActiveRecord::Base.transaction do
      @territory_creation_request&.update!(response: :accepted)
      territory.save!
      organisation.save!
      if lieu.address.present?
        lieu.save!
      end

      self.agent = find_or_invite_agent(organisation)

      agent.services.each do |service|
        TerritoryService.create!(service: service, territory: territory)
      end

      if organisation.ants_connectable
        create_mairie_motifs!
        organisation.territory.add_ants_motif_categories
      elsif OauthApplication.agent_is_verified_by_an_application?(agent)
        # On ne propose pas encore la création de motifs depuis les intégrations, donc on continue de créer des motifs par défaut dans ce cas
        create_example_motifs!
      end

      AgentTerritorialRole.create!(agent: agent, territory: territory)
      AgentTerritorialAccessRight.create!(
        agent: agent, territory: territory,
        allow_to_manage_access_rights: true,
        allow_to_invite_agents: true
      )

      if agent.invitation_created_at.nil? # On n'envoie pas ce mail si l'agent a déjà reçu un mail d'invitation
        Agents::TerritoryCreationRequestMailer.accepted(
          agent: agent,
          organisation: organisation,
          domain_id: @current_domain.id
        ).deliver_later
      end
      true
    end
  end

  # Utilisé par Administrate afin de récupérer la liste des objets (ou ressources)
  # Nécessaire parce que la classe n'hérite pas de ActiveRecord::Base
  def self.default_scoped
    Territory.none
  end

  # Cette méthode est nécessaire pour que Administrate affiche le bouton de création d'une nouvelle resource
  # Autrement, #to_s génère une valeurs sous la forme "Compte#11111" qui ne match avec aucune route
  def to_s
    "compte"
  end

  def self.upsert_france_service_motifs!(organisation)
    Motif.transaction do
      YAML.load_file(Rails.root.join("lib/assets/motifs_france_service.yaml").to_s).map(&:symbolize_keys).each do |template_attrs|
        service_name = template_attrs[:service_name]
        service = Service.find_by(name: service_name) || Service.create!(name: service_name, short_name: service_name)

        motif_attrs = template_attrs
          .slice(:name, :location_type, :default_duration_in_min, :restriction_for_rdv, :instruction_for_rdv)
          .merge(organisation_id: organisation.id, service_id: service.id, color: "#99CC99")

        next if Motif.exists?(motif_attrs.slice(:name, :location_type, :organisation_id, :service_id))

        Motif.create!(motif_attrs)
      end
    end
  end

  private

  def find_or_invite_agent(organisation)
    agent = find_agent
    if agent
      agent.update!(
        @attributes[:agent].merge(
          roles_attributes: [{ organisation: organisation, access_level: AgentRole::ACCESS_LEVEL_ADMIN }]
        )
      )
      agent
    else
      Agent.invite!(@attributes[:agent].merge(
                      roles_attributes: [{ organisation: organisation, access_level: AgentRole::ACCESS_LEVEL_ADMIN }],
                      password: SecureRandom.base64(32)
                    ))
    end
  end

  def find_agent
    Agent.find_by(id: @attributes.dig(:agent, :id)) || Agent.find_by(email: @attributes.dig(:agent, :email))
  end

  def create_mairie_motifs!
    create_mairie_motif!("Carte d'identité", Api::Ants::EditorController::CNI_MOTIF_CATEGORY_NAME)
    create_mairie_motif!("Passeport", Api::Ants::EditorController::PASSPORT_MOTIF_CATEGORY_NAME)
    create_mairie_motif!("Passeport et carte d'identité", Api::Ants::EditorController::CNI_AND_PASSPORT_MOTIF_CATEGORY_NAME)
  end

  def create_mairie_motif!(name, motif_category_name)
    Motif.create!(
      name: name,
      color: "#99CC99",
      default_duration_in_min: 15,
      location_type: :public_office,
      organisation: organisation,
      motif_category: MotifCategory.find_by(name: motif_category_name),
      bookable_by: :everyone
    )
  end

  def create_example_motifs!
    default_motif_attributes = {
      organisation: organisation,
      name: "Suivi de dossier",
      color: "#99CC99",
      default_duration_in_min: 30,
      bookable_by: :agents,
    }
    Motif.create!(default_motif_attributes.merge(location_type: :phone))
    Motif.create!(default_motif_attributes.merge(location_type: :visio))
    Motif.create!(default_motif_attributes.merge(location_type: :public_office))
  end
end
