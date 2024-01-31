# Utilisé uniquement au niveau du SuperAdmin, pour ouvrir un compte
class Compte
  include ActiveModel::Model

  attr_accessor :territory, :organisation, :lieu, :agent

  def initialize(attributes)
    @attributes = attributes
  end

  def save
    self.territory = Territory.new(@attributes[:territory])
    self.organisation = Organisation.new(@attributes[:organisation].merge(territory: territory))
    self.lieu = Lieu.new(@attributes[:lieu].merge(
                           organisation: organisation,
                           name: organisation.name,
                           availability: :enabled
                         ))

    ActiveRecord::Base.transaction do
      territory.save!
      organisation.save!
      lieu.save!

      self.agent = Agent.invite!(@attributes[:agent].merge(
                                   password: SecureRandom.hex,
                                   roles_attributes: [{ organisation: organisation, access_level: AgentRole::ACCESS_LEVEL_ADMIN }]
                                 ))

      AgentTerritorialRole.create!(agent: agent, territory: territory)
      AgentTerritorialAccessRight.create!(
        agent: agent, territory: territory,
        allow_to_manage_access_rights: true,
        allow_to_invite_agents: true,
        allow_to_download_metrics: true
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
end
