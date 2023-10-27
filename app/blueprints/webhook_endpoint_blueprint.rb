class WebhookEndpointBlueprint < Blueprinter::Base
  identifier :id

  fields :target_url, :organisation_id, :subscriptions
end
