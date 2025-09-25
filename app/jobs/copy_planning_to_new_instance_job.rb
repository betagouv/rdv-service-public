class CopyPlanningToNewInstanceJob < ApplicationJob
  # Les objets qu'on copie dans ce job (rdvs, plage ouverture, absence) ont besoin que les objets
  # de configuration (agents, motifs, lieux) soient déjà créés dans la nouvelle organisation.
  # On les copie donc dans ce deuxième batch, après que le premier ai copié tous les objets de config.
  def perform(batch, _context)
    instance_export = InstanceExport.find(batch.properties[:instance_export_id])
    current_domain_id = batch.properties[:current_domain_id]

    source_organisation = instance_export.source_organisation

    instance_export.transaction do
      copy_planning_batch = GoodJob::Batch.new(instance_export_id: instance_export.id)

      copy_planning_batch.enqueue do
        source_organisation.rdvs.future.not_cancelled.pluck(:id).each do |rdv_id|
          CopyRdvAsAbsenceJob.perform_later(instance_export.id, rdv_id, current_domain_id)
        end

        organisation_absences = Absence.where(agent_id: source_organisation.agents.select(:agent_id)).not_expired

        organisation_absences.pluck(:id).each do |absence_id|
          CopyAbsenceJob.perform_later(instance_export.id, absence_id, current_domain_id)
        end

        source_organisation.plage_ouvertures.not_expired.pluck(:id).each do |plage_ouverture_id|
          CopyPlageOuvertureJob.perform_later(instance_export.id, plage_ouverture_id)
        end
      end

      instance_export.update(
        good_job_batch_id: copy_planning_batch.id,
        status: "copying_planning"
      )
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
        params[:agent_email] = absence.agent.email
      end

      api_client = instance_export.api_client
      api_client.post("absences", params)
    end
  end

  class CopyPlageOuvertureJob < ApplicationJob
    queue_as :latency_5m

    def perform(instance_export_id, plage_ouverture_id)
      plage_ouverture = PlageOuverture.find(plage_ouverture_id)
      instance_export = InstanceExport.find(instance_export_id)

      params = {
        title: plage_ouverture.title,
        recurrence: Montrose::Recurrence.dump(plage_ouverture.recurrence),
        first_day: plage_ouverture.first_day.strftime("%Y-%m-%d"),
        start_time: plage_ouverture.start_time.strftime("%H:%M"),
        end_time: plage_ouverture.end_time.strftime("%H:%M"),
        lieu_external_id: plage_ouverture.lieu_id,
        secondary_start_time: plage_ouverture.secondary_start_time&.strftime("%H:%M"),
        secondary_end_time: plage_ouverture.secondary_end_time&.strftime("%H:%M"),
        motif_external_ids: plage_ouverture.motif_ids,
        organisation_id: instance_export.destination_organisation_id,

        external_reference: { external_id: plage_ouverture_id },
      }

      if plage_ouverture.agent != instance_export.agent
        params[:agent_email] = plage_ouverture.agent.email
      end

      api_client = instance_export.api_client
      api_client.post("plage_ouvertures", params)
    end
  end
end
