class ParticipationsExportPageJob < ExportJob
  def perform(participations_ids, page_index, export_id)
    rows = ParticipationExporter.rows_from_participations(Participation.where(id: participations_ids).order(id: :desc))

    ExportFileBlob.create!(export_id: export_id, page_index: page_index, data: rows.to_json)
  end
end
