class ParticipationsExportSendEmailJob < ExportJob
  def perform(batch, _params)
    export = Export.find(batch.properties[:export_id])

    redis_connection = Redis.new(url: Rails.configuration.x.redis_url)
    redis_key = redis_key(export.id)

    pages = redis_connection.hgetall(redis_key)

    page_numbers = pages.keys.map(&:to_i).sort

    rdvs_rows = []
    page_numbers.each do |page_number|
      page = JSON.parse(pages[page_number.to_s])

      rdvs_rows += page
    end

    xls_string = ParticipationExporter.xls_string_from_participations_rows(rdvs_rows)

    export.update!(content: Base64.encode64(xls_string))

    # Using #deliver_now because we don't want to enqueue a job with a huge payload
    Agents::ExportMailer.participations_export(export.id).deliver_now

    redis_connection.del(redis_key)
  ensure
    redis_connection&.close
  end
end
