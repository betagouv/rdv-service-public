class ParticipationsExportPageJob < ExportJob
  def perform(participations_ids, page_index, export_id)
    redis_key = redis_key(export_id)

    rows = ParticipationExporter.rows_from_participations(Participation.where(id: participations_ids).order(id: :desc))

    redis_connection = Redis.new(url: Rails.configuration.x.redis_url)
    redis_connection.hset(redis_key, page_index, rows.to_json)
    redis_connection.expire(redis_key, 1.week)
  ensure
    redis_connection&.close
  end
end
