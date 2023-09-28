# frozen_string_literal: true

class RdvsExportSendEmailJob < ExportJob
  def perform(batch, _params)
    agent = Agent.find(batch.properties[:agent_id])

    # Le département du Var se base sur la position de chaque caractère du nom
    # de fichier pour extraire la date et l'ID d'organisation, donc
    # si on modifie le fichier il faut soit les prévenir soit ajouter à la fin.
    redis_connection = Redis.new(url: Rails.configuration.x.redis_url)
    redis_key = batch.properties[:redis_key]

    pages = redis_connection.hgetall(redis_key)

    page_numbers = pages.keys.map(&:to_i).sort

    rdvs_rows = []
    page_numbers.each do |page_number|
      page = JSON.parse(pages[page_number.to_s])

      page.each do |row|
        rdvs_rows += row
      end
    end

    xls_string = RdvExporter.workbook_from_rdvs_rows(rdvs_rows)

    # Using #deliver_now because we don't want to enqueue a job with a huge payload
    Agents::ExportMailer.rdv_export(agent, batch.properties[:file_name], xls_string).deliver_now
  end
end
