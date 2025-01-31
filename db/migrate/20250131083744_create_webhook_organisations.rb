class CreateWebhookOrganisations < ActiveRecord::Migration[7.1]
  def up
    create_table :webhook_organisations do |t|
      t.references :webhook_endpoint, index: true, foreign_key: true
      t.references :organisation, index: true, foreign_key: true

      t.datetime :created_at, null: false
    end

    add_index :webhook_organisations, %i[webhook_endpoint_id organisation_id], unique: true
    remove_index :webhook_endpoints, %w[organisation_id target_url]

    webhook_types = WebhookEndpoint.all.to_a.group_by { [_1.territory_id, _1.target_url, _1.secret, _1.subscriptions] }
    webhook_types.each do |(territory_id, target_url, secret, subscriptions), existing_endpoints|
      unique_endpoint = WebhookEndpoint.create!(
        territory_id:, target_url:, secret:, subscriptions:,
        organisation_id: existing_endpoints.first.organisation_id, # arbitraire, la colonne va être supprimée juste après
        created_at: existing_endpoints.map(&:created_at).min, # on conserve la date de création du plus vieux endpoint existant
        updated_at: existing_endpoints.map(&:updated_at).max # on conserve la date de touch du plus récent endpoint existant
      )
      existing_endpoints.each do |webhook|
        WebhookOrganisation.create!(
          webhook_endpoint: unique_endpoint,
          organisation_id: webhook.organisation_id,
          created_at: webhook.created_at
        )
      end
      existing_endpoints.each(&:destroy!)
    end

    safety_assured do
      remove_column :webhook_endpoints, :organisation_id
    end
  end

  def down
    add_reference :webhook_endpoints, :organisation, foreign_key: true, index: false
    add_index :webhook_endpoints, %w[organisation_id target_url]

    WebhookEndpoint.all.each do |webhook|
      webhook_organisations = webhook.webhook_organisations.to_a

      # On re-crée un endpoint par orga
      webhook_organisations.each do |webhook_organisation|
        new_webhook = webhook.dup
        new_webhook.organisation_id = webhook_organisation.organisation_id
        new_webhook.created_at = webhook_organisation.created_at
        new_webhook.save!(validate: false)
      end

      # On supprime les données
      WebhookOrganisation.where(webhook_endpoint_id: webhook.id).delete_all
      WebhookEndpoint.where(id: webhook.id).delete_all
    end

    drop_table :webhook_organisations
  end
end
