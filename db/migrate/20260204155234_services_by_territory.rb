class ServicesByTerritory < ActiveRecord::Migration[8.0]
  def up
    # Ces index ne sont pas essentiels et leur unicité nous bloque,
    # je propose de les virer pour le moment.
    remove_index :services, name: :index_services_on_lower_name
    remove_index :services, name: :index_services_on_lower_short_name

    # TODO: plus nécessaire quand on aura mergé la PR séparée qui vire cette colonne
    safety_assured do
      remove_column :oauth_applications, :default_service_id
    end

    # On force avec safety_assured parce :
    # > Adding a foreign key blocks writes on both tables.
    # Oui mais on écrit très peu fréquemment dans ces tables donc c'est OK
    safety_assured do
      add_reference :services, :territory, foreign_key: true, index: true
    end

    self.class.split_services_by_territory
  end

  def self.split_services_by_territory
    Territory.find_each do |territory|
      agent_ids = Set.new
      agent_ids += territory.agent_territorial_access_rights.pluck(:agent_id)
      agent_ids += territory.roles.pluck(:agent_id)
      agent_ids += AgentRole.joins(:organisation).merge(territory.organisations).pluck(:agent_id)

      AgentService.where(agent_id: agent_ids).includes(:service).to_a.group_by(&:service).each do |legacy_service, agent_services|
        new_service = Service.find_or_create_by!(
          territory_id: territory.id,
          name: legacy_service.name,
          short_name: legacy_service.short_name
        )

        agent_services.each do |agent_service|
          AgentService.find_or_create_by!(
            agent_id: agent_service.agent_id,
            service_id: new_service.id,
            created_at: agent_service.created_at
          )
        end

        Motif.where(organisation_id: territory.organisations, service_id: legacy_service.id).update_all(service_id: new_service.id)
        TerritoryService.where(territory:).delete_all
      end
    end

    legacy_services = Service.where(territory_id: nil)
    AgentService.where(service_id: legacy_services).delete_all
    legacy_services.delete_all
  end

  def down
    raise "TODO"
    remove_column :services, :territory_id
  end
end
