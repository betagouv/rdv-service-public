class AddTerritoryServices < ActiveRecord::Migration[7.0]
  def up
    create_table :territory_services do |t|
      t.references :territory, foreign_key: true, index: true
      t.references :service, foreign_key: true, index: true

      t.datetime :created_at, null: false
    end

    add_index :territory_services, %i[territory_id service_id], unique: true

    Territory.all.each do |territory|
      service_ids = AgentService.joins(:agent).merge(territory.organisations_agents).distinct.pluck(:service_id).uniq
      service_ids.each do |service_id|
        TerritoryService.create!(service_id: service_id, territory: territory)
      end
    end
  end

  def down
    drop_table :territory_services
  end
end
