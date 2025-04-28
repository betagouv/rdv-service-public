# Permet d'ouvrir un "compte", c'est à dire un nouveau territoire avec une organisation, et quelques infos supplémentaires
class Compte
  include ActiveModel::Model

  CATEGORIES = %w[État Département Intercommunalité Commune Région Opérateur Association Inconnu].freeze

  attr_accessor :territory, :organisation, :lieu, :agent

  def initialize(attributes, current_domain = nil)
    @attributes = attributes
    @current_domain = current_domain
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
        add_mairie_motifs_categories!
      else
        create_example_motifs!
      end

      AgentTerritorialRole.create!(agent: agent, territory: territory)
      AgentTerritorialAccessRight.create!(
        agent: agent, territory: territory,
        allow_to_manage_access_rights: true,
        allow_to_invite_agents: true
      )
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
    service = Service.find_by(name: Service::MAIRIE)

    create_mairie_motif!(service, "Carte d'identité", Api::Ants::EditorController::CNI_MOTIF_CATEGORY_NAME)
    create_mairie_motif!(service, "Passeport", Api::Ants::EditorController::PASSPORT_MOTIF_CATEGORY_NAME)
    create_mairie_motif!(service, "Passeport et carte d'identité", Api::Ants::EditorController::CNI_AND_PASSPORT_MOTIF_CATEGORY_NAME)
  end

  def create_mairie_motif!(service, name, motif_category_name)
    Motif.create!(
      name: name,
      color: "#99CC99",
      default_duration_in_min: 15,
      location_type: :public_office,
      organisation: organisation,
      service: service,
      motif_category: MotifCategory.find_by(name: motif_category_name),
      bookable_by: :everyone
    )
  end

  def add_mairie_motifs_categories!
    Api::Ants::EditorController::ANTS_MOTIF_CATEGORY_NAMES.each do |name|
      organisation.territory.motif_categories << MotifCategory.find_by(name: name)
    end
  end

  def create_example_motifs!
    default_motif_attributes = {
      organisation: organisation,
      name: "Suivi de dossier",
      color: "#99CC99",
      default_duration_in_min: 30,
      bookable_by: :agents,
      service: agent.services.first,
    }
    Motif.create!(default_motif_attributes.merge(location_type: :phone))
    Motif.create!(default_motif_attributes.merge(location_type: :visio))
    Motif.create!(default_motif_attributes.merge(location_type: :public_office))
  end
end
