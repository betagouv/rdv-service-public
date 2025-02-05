# Ce script permet de sortir une mairie du territory historique des mairies, pour lui donner son propre territoire.

# exemple pour une mairie a juste une organisation dans le territoire existant:
# ExtractMairieFromTerritory.run(110, 155)
#
# exemple pour une mairie qui a une organisation dans le territoire mairie et une autre organisation dans un autre territoire
# on peut déplacer l'organisation du territoire mairie en faisant:
# ExtractMairieFromTerritory.run(454, 952, new_territory_id: 265)

class MotifCategoriesTerritory < ApplicationRecord
  belongs_to :motif_category
  belongs_to :territory
end

class ExtractMairieFromTerritory
  # organisation_id : l'id de l'organisation d'origine de la mairie
  def self.run(organisation_id, admin_agent_id, new_territory_id: nil)
    new(organisation_id, admin_agent_id, new_territory_id:).run
  end

  def initialize(organisation_id, admin_agent_id, new_territory_id:)
    @organisation_id = organisation_id
    @admin_agent_id = admin_agent_id
    @new_territory = Territory.find_by(id: new_territory_id)
  end

  def run
    ActiveRecord::Base.logger = Logger.new($stdout)

    ActiveRecord::Base.transaction do
      @new_territory ||= Territory.create!(
        name: organisation.name,
        departement_number: departement_number
      )
      organisation.update!(territory: @new_territory)

      organisation.agents.each do |agent|
        agent.agent_territorial_access_rights.where(territory_id: mairies_territory.id).each do |rights|
          rights.update!(territory: @new_territory)
        end
      end

      MotifCategory.requires_ants_predemande_number.each do |motif_category|
        MotifCategoriesTerritory.create(
          motif_category: motif_category,
          territory: @new_territory
        )
      end

      # On ne met que les services des agents de la mairie
      # Le territoire mairies a beaucoup de services utilisés par une seule mairie
      organisation.agents.map(&:services).flatten.each do |service|
        TerritoryService.create(
          territory: @new_territory,
          service: service
        )
      end
      AgentTerritorialRole.find_or_initialize_by(
        territory: @new_territory,
        agent_id: @admin_agent_id
      ).save
    end
  end

  private

  def departement_number
    zipcode_regex = /\d{5}/
    zipcode = organisation.lieux.first.address[zipcode_regex]

    zipcode[0..1]
  end

  def mairies_territory
    @mairies_territory ||= Territory.find_by(name: Territory::MAIRIES_NAME)
  end

  def organisation
    @organisation ||= Organisation.find(@organisation_id)
  end
end
