class ParticipationsExportSendEmailJob < ExportJob
  def perform(batch, _params)
    export = Export.find(batch.properties[:export_id])
    redis_key = redis_key(export.id)

    page_numbers = Redis.with_connection { |redis| redis.hkeys(redis_key).map(&:to_i).sort }

    rows_enum = Enumerator.new do |yielder|
      page_numbers.each do |page_number|
        json = Redis.with_connection { |redis| redis.hget(redis_key, page_number) }

        JSON.parse(json).each do |row|
          yielder << row
        end
      end
    end

    Tempfile.create do |file|
      ParticipationExporter.write_xls_to_io(file, rows_enum)
      file.rewind
      export.store_file(file.read)
    end

    Agents::ExportMailer.participations_export(export.id).deliver_later
  end
end
