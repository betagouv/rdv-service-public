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

    destination_org = api_client.post("organisations", new_org_attributes)["organisation"]

    update!(destination_organisation_id: destination_org["id"])
  end

  def source_organisation
    agent.organisations.first
  end

  def destination_organisation
    @destination_organisation ||= Organisation.new(new_instance_organisations.first).tap(&:readonly!)
  end

  def copy_to_new_instance!(current_domain)
    batch = GoodJob::Batch.new(instance_export_id: id)

    transaction do
      batch.add do
        source_organisation.users.pluck(:id).each do |user_id|
          CopyUserJob.perform_later(id, user_id, current_domain.id)
        end
        source_organisation.agents.where.not(id: agent.id).pluck(:id).each do |agent_id|
          CopyAgentJob.perform_later(id, agent_id)
        end
      end
      update(good_job_batch_id: batch.id)
    end
  end

  class CopyAgentJob < ApplicationJob
    queue_as :latency_5m

    def perform(instance_export_id, agent_id)
      InstanceExport.find(instance_export_id).copy_agent!(agent_id)
    end
  end

  def copy_agent!(agent_id)
    agent = Agent.find(agent_id)
    api_client.post("agents", {
                      email: agent.email,
                      organisation_ids: [destination_organisation_id],
                      access_level: agent.role_in_organisation(source_organisation).access_level,
                    })
  end

  class CopyUserJob < ApplicationJob
    queue_as :latency_5m

    def perform(instance_export_id, user_id, domain_id)
      InstanceExport.find(instance_export_id).copy_user!(user_id, Domain.find(domain_id))
    end
  end

  def copy_user!(user_id, domain)
    user = User.find(user_id)
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
