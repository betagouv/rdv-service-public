class WebhookEndpointBlueprint < Blueprinter::Base
  identifier :id

  fields :target_url, :subscriptions

  association :organisations, blueprint: OrganisationBlueprint
end
