# frozen_string_literal: true

class RdvsExportSendEmailJob < ExportJob
  def perform(batch, _params)
    redis_key = batch.properties[:redis_key]
    xls_string = "" # aller cherche dans redis

    # Using #deliver_now because we don't want to enqueue a job with a huge payload
    Agents::ExportMailer.rdv_export(agent, file_name, xls_string).deliver_now
  end
end
