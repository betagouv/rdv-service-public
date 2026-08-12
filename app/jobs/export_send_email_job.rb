class ExportSendEmailJob < ExportJob
  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    perform_limit: 1,
    key: -> { "high_ram_usage_export" }
  )

  MAILER_CLASS_FOR_EXPORT_TYPE = {
    Export::RDV_EXPORT => :rdv_export,
    Export::PARTICIPATIONS_EXPORT => :participations_export,
  }.freeze

  CLASS_FOR_EXPORT_TYPE = {
    Export::RDV_EXPORT => "RdvExporter",
    Export::PARTICIPATIONS_EXPORT => "ParticipationExporter",
  }.freeze

  def perform(batch, _params)
    @export = Export.find(batch.properties[:export_id])
    page_blobs = @export.export_file_blobs.pages.order(:page_index)

    rows_enum = Enumerator.new do |yielder|
      # On a pas besoin du cache ActiveRecord ici, on évite donc
      # d'y stocker un gros volume de donnée pour économiser de la RAM.
      ExportFileBlob.uncached do
        page_blobs.in_batches(of: 10) do |page_blobs_batch|
          page_blobs_batch.pluck(:data) do |json_rows|
            JSON.parse(json_rows).each do |row|
              yielder << row
            end
          end
        end
      end
    end

    Tempfile.create do |file|
      if @export.export_type == Export::RDV_EXPORT
        RdvExporter.write_xls_to_io(file, rows_enum)
      else
        ParticipationExporter.write_xls_to_io(file, rows_enum)
      end
      file.rewind
      @export.store_file(file.read)
    end

    page_blobs.delete_all

    mailer_method = MAILER_CLASS_FOR_EXPORT_TYPE.fetch(@export.export_type)
    Agents::ExportMailer.public_send(mailer_method, @export.id).deliver_later
  end
end
