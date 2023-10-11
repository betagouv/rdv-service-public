# frozen_string_literal: true

class AddTerritoryIdToServices < ActiveRecord::Migration[7.0]
  def change
    add_reference :services, :territory, foreign_key: true, index: true

    remove_index :services, name: "index_services_on_lower_name"
    remove_index :services, name: "index_services_on_lower_short_name"
    add_index :services, %i[territory_id name], unique: true
    add_index :services, %i[territory_id short_name], unique: true

    # Ce script a pour vocation de créer les services en spécifiant leur territoire, sur la base des services existant
    # Pour chaque service, identifier les territoires liés
    # Pour chaque service:
    #  - Pour chaque territoire du service:
    #     - Dupliquer le service dans le territoire
    #     - Mettre à jour tous les agents du territoire avec le nouveau service
    #     - Mettre à jour tous les motifs du territoire avec le nouveau service
    #
    # Supprimer tous les services sans TerritoryID

    services_of_agents = Service.joins(
      agents: { organisations: :territory }
    ).select(
      :id, "ARRAY_AGG(DISTINCT territories.id) as territories_ids"
    ).group(
      :id
    ).map { |s| [s.id, s.territories_ids] }.to_h

    services_of_motifs = Service.joins(
      motifs: { organisation: :territory }
    ).select(
      :id, "ARRAY_AGG(DISTINCT territories.id) as territories_ids"
    ).group(
      :id
    ).map { |s| [s.id, s.territories_ids] }.to_h

    territories_by_service = {}
    services_of_agents.each do |service_id, territories_ids|
      territories_by_service[service_id] ||= []
      territories_by_service[service_id] += territories_ids
    end
    services_of_motifs.each do |service_id, territories_ids|
      territories_by_service[service_id] ||= []
      territories_by_service[service_id] += territories_ids
    end

    migrate_services(territories_by_service)

    # Certains agents ne sont pas liés à une orga, il faut donc les mettre à jour en cherchant leur territoire via RDV
    Agent.left_outer_joins(:roles).where(agent_roles: { id: nil }).includes(:rdvs, :territorial_roles, :agent_territorial_access_rights).each do |agent|
      territory_id = agent.rdvs.first&.territory&.id || agent.territorial_roles.first&.territory_id || agent.agent_territorial_access_rights.first&.territory_id
      if territory_id
        agent_service = Service.find_or_create_by!(
          name: agent.service.name,
          short_name: agent.service.short_name,
          territory_id: territory_id
        )
        agent.update_columns(service_id: agent_service.id)
      else
        agent.destroy!
      end
    end

    Service.where(territory_id: nil).destroy_all
  end

  def migrate_services(services)
    Service.transaction do
      services.each do |service_id, territories_ids|
        service = Service.find(service_id)
        territories_ids.each do |territory_id|
          new_service = Service.find_or_create_by!(
            name: service.name,
            short_name: service.short_name,
            territory_id: territory_id
          )

          Agent.joins(organisations: :territory).where(service_id: service.id, organisations: { territory_id: territory_id }).update_all(service_id: new_service.id)
          Motif.joins(organisation: :territory).where(service_id: service.id, organisation: { territory_id: territory_id }).update_all(service_id: new_service.id)
        end
      end
    end
  end
end
