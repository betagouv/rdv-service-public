class InstanceExport < ApplicationRecord
  belongs_to :agent

  encrypts :api_token
  encrypts :refresh_token

  def new_instance_organisations
    response = Faraday.get(
      "#{ENV['RDV_SERVICE_PUBLIC_OAUTH_BASE_URL']}/api/v1/organisations",
      {},
      request_headers
    )

    JSON.parse(response.body)["organisations"]
  end

  def source_organisation
    agent.organisations.first
  end

  def destination_organisation
    @destination_organisation ||= Organisation.new(new_instance_organisations.first).tap(&:readonly!)
  end

  def copy_users!(current_domain)
    source_organisation.users.limit(1).map do |user|
      request_body = user.attributes.symbolize_keys.slice(*UserBlueprint.reflections[:default].fields.keys - %i[id responsible_id])
      request_body[:organisation_ids] = [destination_organisation_id]

      request_body[:external_references] = [{
        external_id: user.id,
        external_url: Rails.application.routes.url_helpers.admin_organisation_user_url(source_organisation.id, user.id, host: current_domain.host_name),
      }]

      Faraday.post(
        "#{ENV['RDV_SERVICE_PUBLIC_OAUTH_BASE_URL']}/api/v1/users",
        request_body.to_json,
        request_headers
      )
    end
  end

  private

  def request_headers
    {
      "Authorization" => "Bearer #{api_token}",
      "Content-Type" => "application/json",
    }
  end
end
