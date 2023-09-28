# frozen_string_literal: true

class RdvsExportPageJob < ExportJob
  def perform(rdv_ids, page_index, redis_key)
    rows = RdvExporter.rows_from_rdvs(Rdv.where(id: rdv_ids)).order(starts_at: :desc)

    redis_connection = Redis.new(url: Rails.configuration.x.redis_url)
    redis_connection.hset(redis_key, page_index, rows.to_json)
    redis_connection.expire(redis_key, 1.week)
    redis_connection.close
  end
end
