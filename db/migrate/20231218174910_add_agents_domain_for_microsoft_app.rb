class AddAgentsDomainForMicrosoftApp < ActiveRecord::Migration[7.0]
  def change
    add_column :agents, :domain_for_microsoft_app, :string, comment: "Le domaine utilisé pour se connecter à l'appli Microsoft qui gère la synchro Outlook"
  end
end
