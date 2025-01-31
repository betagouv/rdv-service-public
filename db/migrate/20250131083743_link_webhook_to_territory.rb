class LinkWebhookToTerritory < ActiveRecord::Migration[7.1]
  def change
    # L'ajout d'index et clé étrangère bloque les écritures sur les tables webhook_endpoints
    # et territories, mais vu la taille des tables, on peut bloquer l'écriture pendant 10ms.
    safety_assured do
      add_reference :webhook_endpoints, :territory, index: true, foreign_key: true
    end

    reversible do |direction|
      direction.up do
        WebhookEndpoint.all.each do |webhook|
          webhook.update_columns(territory_id: Organisation.find(webhook.organisation_id).territory_id)
        end
      end
    end

    # L'ajout de NOT NULL bloque les écritures sur la tables webhook_endpoints,
    # mais vu la taille de la table, on peut bloquer l'écriture pendant 10ms.
    safety_assured do
      change_column_null :webhook_endpoints, :territory_id, false
    end
  end
end
