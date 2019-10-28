class AgentHasManyOrganisations < ActiveRecord::Migration[6.0]
  class Agent < ActiveRecord::Base
    belongs_to :organisation, optional: true
    has_and_belongs_to_many :organisations, -> { distinct }
  end

  def up
    create_table :agents_organisations, id: false do |t|
      t.belongs_to :agent, index: true
      t.belongs_to :organisation, index: true
    end

    Agent.all.each do |a|
      a.organisations << a.organisation
    end

    remove_column :agents, :organisation_id
  end

  def down
    add_column :agents, :organisation_id, :bigint
    add_index :agents, :organisation_id

    Agent.all.each do |a|
      a.organisation = a.organisations.first
      a.save
    end

    drop_table :agents_organisations
  end
end
