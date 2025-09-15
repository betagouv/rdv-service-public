class InstanceExport < ApplicationRecord
  belongs_to :agent
  belongs_to :good_job_batch, class_name: "GoodJob::BatchRecord", optional: true
  belongs_to :source_organisation, optional: true, class_name: "Organisation"

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
    super || agent.organisations.first
  end

  def destination_organisation
    @destination_organisation ||= Organisation.new(new_instance_organisations.first).tap(&:readonly!)
  end

  def api_client
    @api_client ||= RdvServicePublicApiClient.new(api_token)
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

        source_organisation.lieux.enabled.pluck(:id).each do |lieu_id|
          CopyLieuJob.perform_later(id, lieu_id)
        end

        source_organisation.motifs.active.pluck(:id).each do |motif_id|
          CopyMotifJob.perform_later(id, motif_id)
        end

        source_organisation.rdvs.future.not_cancelled.pluck(:id).each do |rdv_id|
          CopyRdvAsAbsenceJob.perform_later(id, rdv_id, current_domain.id)
        end

        organisation_absences = Absence.where(agent_id: source_organisation.agents.select(:agent_id)).not_expired

        organisation_absences.pluck(:id).each do |absence_id|
          CopyAbsenceJob.perform_later(id, absence_id, current_domain.id)
        end
      end
      update(good_job_batch_id: batch.id)
    end
  end

  class CopyRdvAsAbsenceJob < ApplicationJob
    queue_as :latency_5m

    def perform(instance_export_id, rdv_id, domain_id)
      domain = Domain.find(domain_id)
      instance_export = InstanceExport.find(instance_export_id)
      rdv = Rdv.find(rdv_id)
      rdv.agents.each do |agent|
        params = {
          title: "RDV pris sur #{domain.name}",
          first_day: rdv.starts_at.strftime("%Y-%m-%d"),
          end_day: rdv.starts_at.strftime("%Y-%m-%d"),
          start_time: rdv.starts_at.strftime("%H:%M"),
          end_time: rdv.ends_at.strftime("%H:%M"),
          external_reference: {
            external_id: "rdv:#{rdv_id}", # on créera aussi des external_reference pour des absences, donc on préfixe par "rdv"
            external_url: Rails.application.routes.url_helpers.admin_organisation_rdv_url(rdv.organisation, rdv.id, host: domain.host_name),
          },
        }

        if agent != instance_export.agent
          params[:agent_email] = agent.email
        end
        api_client = instance_export.api_client
        api_client.post("absences", params)
      end
    end
  end

  class CopyAbsenceJob < ApplicationJob
    queue_as :latency_5m

    def perform(instance_export_id, absence_id, domain_id)
      domain = Domain.find(domain_id)
      absence = Absence.find(absence_id)
      instance_export = InstanceExport.find(instance_export_id)

      params = {
        title: absence.title,
        recurrence: Montrose::Recurrence.dump(absence.recurrence),
        first_day: absence.first_day.strftime("%Y-%m-%d"),
        end_day: absence.end_day.strftime("%Y-%m-%d"),
        start_time: absence.start_time.strftime("%H:%M"),
        end_time: absence.end_time.strftime("%H:%M"),

        external_reference: {
          external_id: "absence:#{absence_id}", # on préfixe par absence pour éviter la collision avec les rendez-vous
          external_url: Rails.application.routes.url_helpers.edit_admin_organisation_planning_absence_url(
            instance_export.source_organisation.id, absence.id, host: domain.host_name
          ),
        },
      }

      if absence.agent != instance_export.agent
        params[:agent_email] = agent.email
      end

      api_client = instance_export.api_client
      api_client.post("absences", params)
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
      attributes = lieu.attributes.slice(*%w[name address latitude longitude phone_number])

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
