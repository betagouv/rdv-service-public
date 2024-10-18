class RdvsExportPageJob < ExportJob
  def perform(rdv_ids, page_index, export_id)
    redis_key = redis_key(export_id)

    rows = RdvExporter.rows_from_rdvs(Rdv.where(id: rdv_ids).order(starts_at: :desc))

    Redis.with_connection do |redis|
      redis.hset(redis_key, page_index, rows.to_json)
      redis.expire(redis_key, 1.week)
    end
  end
end
