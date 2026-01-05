class RdvsExportSendEmailJob < ExportJob
  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    perform_limit: 1,
    key: -> { "high_ram_usage_export" }
  )

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
      RdvExporter.write_xls_to_io(file, rows_enum)
      file.rewind
      export.store_file(file.read)
    end

    Agents::ExportMailer.rdv_export(export.id).deliver_later
  end
end
