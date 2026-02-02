class InstanceExport < ApplicationRecord
  belongs_to :agent
  belongs_to :good_job_batch, class_name: "GoodJob::BatchRecord", optional: true
  belongs_to :source_organisation, optional: true, class_name: "Organisation"

  encrypts :api_token
  encrypts :refresh_token

  scope :finished_exports_for_organisation, lambda { |source_organisation_id|
    where(source_organisation_id: source_organisation_id, status: "motifs_archived")
  }

  validates :status, in: %w[oauth_connected copying_configuration copying_planning motifs_archived]

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
    super || agent.organisations.first
  end

  def api_client
    @api_client ||= RdvServicePublicApiClient.new(api_token)
  end

  def copy_to_new_instance!(current_domain)
    batch = GoodJob::Batch.new(instance_export_id: id)

    batch.properties = { instance_export_id: id, current_domain_id: current_domain.id }
    batch.on_success = "CopyPlanningToNewInstanceJob"

    transaction do
      batch.enqueue do
        source_organisation.users.pluck(:id).each do |user_id|
          CopyUserJob.perform_later(id, user_id, current_domain.id)
        end

        source_organisation.agents.where.not(id: agent.id).pluck(:id).each do |agent_id|
          CopyAgentJob.perform_later(id, agent_id)
        end

        source_organisation.lieux.pluck(:id).each do |lieu_id|
          CopyLieuJob.perform_later(id, lieu_id)
        end

        source_organisation.motifs.pluck(:id).each do |motif_id|
          CopyMotifJob.perform_later(id, motif_id)
        end
      end

      update(status: "copying_configuration")
    end
  end

  MOTIF_ATTRIBUTE_NAMES = %i[
    name
    color
    default_duration_in_min
    min_public_booking_delay
    max_public_booking_delay
    restriction_for_rdv
    instruction_for_rdv
    for_secretariat
    follow_up
    visibility_type
    custom_cancel_warning_message
    collectif
    location_type
    rdvs_editable_by_user
    rdvs_cancellable_by_user
    bookable_by
    deleted_at
  ].freeze

  class CopyMotifJob < ApplicationJob
    queue_as :latency_5m

    def perform(instance_export_id, motif_id)
      instance_export = InstanceExport.find(instance_export_id)
      motif = Motif.find(motif_id)
      attributes = motif.attributes.symbolize_keys.slice(*MOTIF_ATTRIBUTE_NAMES)

      attributes[:external_reference] = { external_id: motif.id }
      attributes[:organisation_id] = instance_export.destination_organisation_id

      instance_export.api_client.post("motifs", attributes)
    end
  end

  class CopyLieuJob < ApplicationJob
    queue_as :latency_5m

    def perform(instance_export_id, lieu_id)
      instance_export = InstanceExport.find(instance_export_id)
      lieu = Lieu.find(lieu_id)
      attributes = lieu.attributes.slice(*%w[name address latitude longitude phone_number availability])

      attributes[:external_reference] = { external_id: lieu.id }
      attributes[:organisation_id] = instance_export.destination_organisation_id

      instance_export.api_client.post("lieux", attributes)
    end
  end

  class CopyAgentJob < ApplicationJob
    queue_as :latency_5m

    def perform(instance_export_id, agent_id)
      instance_export = InstanceExport.find(instance_export_id)
      agent = Agent.find(agent_id)

      instance_export.api_client.post("agents", {
                                        email: agent.email,
                                        organisation_ids: [instance_export.destination_organisation_id],
                                        access_level: agent.role_in_organisation(instance_export.source_organisation).access_level,
                                      })
    end
  end

  class CopyUserJob < ApplicationJob
    queue_as :latency_5m

    def perform(instance_export_id, user_id, domain_id)
      instance_export = InstanceExport.find(instance_export_id)
      domain = Domain.find(domain_id)
      user = User.find(user_id)

      request_body = user.attributes.symbolize_keys.slice(*UserBlueprint.reflections[:default].fields.keys - %i[id responsible_id])
      request_body[:notification_email] ||= request_body.delete(:email) # Les users n'auront pas de mot de passe devise sur la nouvelle instance, donc il faut uniquement utiliser le notification_email
      request_body[:organisation_ids] = [instance_export.destination_organisation_id]

      request_body[:external_reference] = {
        external_id: user.id,
        external_url: Rails.application.routes.url_helpers.admin_organisation_user_url(instance_export.source_organisation.id, user.id, host: domain.host_name),
      }

      instance_export.api_client.post("users", request_body)
    end
  end
end
