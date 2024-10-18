class ParticipationsExportPageJob < ExportJob
  def perform(participations_ids, page_index, export_id)
    redis_key = redis_key(export_id)

    rows = ParticipationExporter.rows_from_participations(Participation.where(id: participations_ids).order(id: :desc))

    Redis.with_connection do |redis|
      redis.hset(redis_key, page_index, rows.to_json)
      redis.expire(redis_key, 1.week)
    end
  end
end
