# frozen_string_literal: true

class UserProfileBlueprint < Blueprinter::Base
  # Blueprints are used :
  # * in the API: See Api::V1::BaseController#render_record and #render_collection
  # * in the webhooks: See WebhookDeliverable#generate_webhook_payload

  association :user, blueprint: UserBlueprint
  association :organisation, blueprint: OrganisationBlueprint

  view :without_user do
    exclude :user
  end
end
