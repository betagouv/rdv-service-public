class CreateWebhookOrganisations < ActiveRecord::Migration[7.1]
  def up
    create_table :webhook_organisations do |t|
      t.references :webhook_endpoint, index: true, foreign_key: true
      t.references :organisation, index: true, foreign_key: true

      t.datetime :created_at, null: false
    end

    organisations_with_webhooks = Organisation.where(id: WebhookEndpoint.select(:organisation_id))
    territories_with_webhooks = organisations_with_webhooks.map(&:territory).uniq
    territories_with_webhooks.each do |territory|
      territory_webhooks = WebhookEndpoint.where(organisation_id: territory.organisation_ids)
      webhook_types = territory_webhooks.group_by { [_1.target_url, _1.secret, _1.subscriptions] }
      webhook_types.each_value do |webhooks|
        # On va créer un webhook et ses entrées de table de jointure, puis supprimer les webhooks existants.
        oldest_webhook, *others = webhooks.sort_by(&:created_at)
        webhooks.each do |webhook|
          WebhookOrganisation.create!(webhook_endpoint: oldest_webhook, organisation_id: webhook.organisation_id, created_at: webhook.created_at)
        end
        others.each(&:destroy!)
      end
    end

    safety_assured do
      remove_index :webhook_endpoints, %w[organisation_id target_url]
      remove_column :webhook_endpoints, :organisation_id
    end
  end

  def down
    add_reference :webhook_endpoints, :organisation, foreign_key: true, index: false
    add_index :webhook_endpoints, %w[organisation_id target_url]

    organisations_with_webhooks = Organisation.where(id: WebhookOrganisation.select(:organisation_id))
    territories_with_webhooks = organisations_with_webhooks.map(&:territory).uniq
    territories_with_webhooks.each do |territory|
      territory_webhooks = WebhookEndpoint.where(id: WebhookOrganisation.where(organisation_id: territory.organisation_ids).select(:webhook_endpoint_id))
      territory_webhooks.each do |webhook|
        orgs = webhook.organisations.to_a
        WebhookOrganisation.where(webhook_endpoint_id: webhook.id).delete_all
        WebhookEndpoint.where(id: webhook.id).delete_all
        orgs.each do |org|
          new_webhook = webhook.dup
          new_webhook.organisation_id = org.id
          new_webhook.save!(validate: false)
        end
      end
    end

    drop_table :webhook_organisations
  end
end
