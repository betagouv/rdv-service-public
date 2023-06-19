# frozen_string_literal: true

class RdvsExportJob < ExportJob
  def perform(agent:, organisation_ids:, options:)
    raise "Agent does not belong to all requested organisation(s)" if (organisation_ids - agent.organisation_ids).any?

    @agent = agent
    now = Time.zone.now
    organisations = agent.organisations.where(id: organisation_ids)
    rdvs = Rdv.search_for(organisations, options)

    # Le département du Var se base sur la position de chaque caractère du nom
    # de fichier pour extraire la date et l'ID d'organisation, donc
    # si on modifie le fichier il faut soit les prévenir soit ajouter à la fin.
    file_name = if organisations.count == 1
                  "export-rdv-#{now.strftime('%Y-%m-%d')}-org-#{organisations.first.id.to_s.rjust(6, '0')}.xls"
                else
                  "export-rdv-#{now.strftime('%Y-%m-%d')}.xls"
                end
    xls_string = RdvExporter.export(rdvs.order(starts_at: :desc))

    # Using #deliver_now because we don't want to enqueue a job with a huge payload
    Agents::ExportMailer.rdv_export(agent, file_name, xls_string).deliver_now
  end
end
