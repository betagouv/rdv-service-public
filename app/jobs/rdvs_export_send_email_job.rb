class RdvsExportSendEmailJob < ExportJob
  def perform(batch, _params)
    export = Export.find(batch.properties[:export_id])

    redis_key = redis_key(export.id)

    pages = Redis.with_connection { |redis| redis.hgetall(redis_key) }

    page_numbers = pages.keys.map(&:to_i).sort

    rdvs_rows = []
    page_numbers.each do |page_number|
      page = JSON.parse(pages[page_number.to_s])

      rdvs_rows += page
    end

    xls_string = RdvExporter.xls_string_from_rdvs_rows(rdvs_rows)

    export.store_file(xls_string)

    Agents::ExportMailer.rdv_export(export.id).deliver_later

    Redis.with_connection { |redis| redis.del(redis_key) }
  end
end
