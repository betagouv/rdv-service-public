class RdvsExportPageJob < ExportJob
  def perform(rdv_ids, page_index, export_id)
    rows = RdvExporter.rows_from_rdvs(Rdv.where(id: rdv_ids).order(starts_at: :desc))

    ExportFileBlob.create!(export_id: export_id, page_index: page_index, data: rows.to_json)
  end
end
