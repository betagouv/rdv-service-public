class ParticipationsExportSendEmailJob < ExportJob
  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    perform_limit: 1,
    key: -> { "high_ram_usage_export" }
  )

  def perform(batch, _params)
    export = Export.find(batch.properties[:export_id])
    page_blobs = export.export_file_blobs.pages.order(:page_index)

    rows_enum = Enumerator.new do |yielder|
      page_blobs.each do |blob|
        JSON.parse(blob.data).each do |row|
          yielder << row
        end
      end
    end

    Tempfile.create do |file|
      ParticipationExporter.write_xls_to_io(file, rows_enum)
      file.rewind
      export.store_file(file.read)
    end

    page_blobs.delete_all

    Agents::ExportMailer.participations_export(export.id).deliver_later
  end
end
