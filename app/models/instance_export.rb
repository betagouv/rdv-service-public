class InstanceExport < ApplicationRecord
  belongs_to :agent
  belongs_to :good_job_batch, class_name: "GoodJob::BatchRecord", optional: true

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
    batch = GoodJob::Batch.new(instance_export_id: id)

    batch.add do
      source_organisation.users.pluck(:id).each do |user_id|
        CopyUserJob.perform_later(id, user_id, current_domain.id)
      end
    end
    update(good_job_batch_id: batch.id)
  end

  class CopyUserJob < ApplicationJob
    queue_as :latency_5m

    def perform(instance_export_id, user_id, domain_id)
      export = InstanceExport.find(instance_export_id)
      user = User.find(user_id)
      export.copy_user!(user, Domain.find(domain_id))
    end
  end

  def copy_user!(user, domain)
    request_body = user.attributes.symbolize_keys.slice(*UserBlueprint.reflections[:default].fields.keys - %i[id responsible_id])
    request_body[:organisation_ids] = [destination_organisation_id]

    request_body[:external_references] = [{
      external_id: user.id,
      external_url: Rails.application.routes.url_helpers.admin_organisation_user_url(source_organisation.id, user.id, host: domain.host_name),
    }]

    Faraday.post(
      "#{ENV['RDV_SERVICE_PUBLIC_OAUTH_BASE_URL']}/api/v1/users",
      request_body.to_json,
      request_headers
    )
  end

  private

  def request_headers
    {
      "Authorization" => "Bearer #{api_token}",
      "Content-Type" => "application/json",
    }
  end
end
