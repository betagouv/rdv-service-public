class AddAgentsDomainForMicrosoftApp < ActiveRecord::Migration[7.0]
  def change
    add_column :agents, :domain_for_microsoft_app, :string
  end
end
