class InstanceExports::CopyConfiguration
  class CopyUserJob < ApplicationJob
    queue_as :latency_5m

    def perform(instance_export_id, user_id, domain_id)
      instance_export = InstanceExport.find(instance_export_id)
      domain = Domain.find(domain_id)
      user = User.find(user_id)

      request_body = user.attributes.symbolize_keys.slice(*UserBlueprint.reflections[:default].fields.keys - %i[id responsible_id])
      request_body[:organisation_ids] = [instance_export.destination_organisation_id]

      request_body[:external_reference] = {
        external_id: user.id,
        external_url: Rails.application.routes.url_helpers.admin_organisation_user_url(instance_export.source_organisation.id, user.id, host: domain.host_name),
      }

      instance_export.api_client.post("users", request_body)
    end
  end
end
