class CreateAgentsServicesJoinTable < ActiveRecord::Migration[6.0]
  def up
    create_table :agents_services do |t|
      t.belongs_to :agent
      t.belongs_to :service
      t.timestamps
    end

    Agent.all.each do |agent|
      agent.services << agent.service
    end
  end

  def down
    drop_table :agents_services
  end
end

class Agent < ApplicationRecord
  has_many :agents_services
  has_many :services, through: :agents_services
end
