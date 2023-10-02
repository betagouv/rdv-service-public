# frozen_string_literal: true

class RdvsExportJob < ExportJob
  def perform(agent:, organisation_ids:, options:)
    raise "Agent does not belong to all requested organisation(s)" if (organisation_ids - agent.organisation_ids).any?

    @agent = agent
    organisations = agent.organisations.where(id: organisation_ids)
    rdvs = Rdv.search_for(organisations, options).order(starts_at: :desc)

    redis_key = "RdvsExportJob-#{SecureRandom.uuid}"

    batch = GoodJob::Batch.new

    batch.properties = { redis_key: redis_key, file_name: file_name(organisations), agent_id: agent.id }

    batch.add do
      rdvs.find_in_batches(batch_size: 200).with_index do |rdv_batch, page_index|
        RdvsExportPageJob.perform_later(rdv_batch.ids, page_index, redis_key)
      end
    end

    batch.enqueue(on_success: RdvsExportSendEmailJob)
  end

  private

  def file_name(organisations)
    today = Time.zone.now.strftime("%Y-%m-%d")
    # Le département du Var se base sur la position de chaque caractère du nom
    # de fichier pour extraire la date et l'ID d'organisation, donc
    # si on modifie le fichier il faut soit les prévenir soit ajouter à la fin.
    if organisations.count == 1
      "export-rdv-#{today}-org-#{organisations.first.id.to_s.rjust(6, '0')}.xls"
    else
      "export-rdv-#{today}.xls"
    end
  end
end
