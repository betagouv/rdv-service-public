class InstanceExport < ApplicationRecord
  belongs_to :agent
  belongs_to :good_job_batch, class_name: "GoodJob::BatchRecord", optional: true

  encrypts :api_token
  encrypts :refresh_token

  def new_instance_organisations
    @new_instance_organisations ||= api_client.get("organisations")["organisations"]
  end

  def create_organisation_on_new_instance!
    new_org_attributes = source_organisation.attributes.slice(*%w[name website phone_number email])
    new_org_attributes.merge!({ external_reference: { external_id: source_organisation.id } })

    destination_org = api_client.post("organisations", new_org_attributes)

    update!(destination_organisation_id: destination_org["id"])
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

    request_body[:external_reference] = {
      external_id: user.id,
      external_url: Rails.application.routes.url_helpers.admin_organisation_user_url(source_organisation.id, user.id, host: domain.host_name),
    }

    api_client.post("users", request_body)
  end

  private

  def api_client
    @api_client ||= RdvServicePublicApiClient.new(api_token)
  end
end
