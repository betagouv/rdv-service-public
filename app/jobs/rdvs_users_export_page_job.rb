# frozen_string_literal: true

class RdvsUsersExportPageJob < ExportJob
  def perform(rdvs_users_ids, page_index, redis_key)
    rows = RdvsUserExporter.rows_from_rdvs_users(RdvsUser.where(id: rdvs_users_ids).order(id: :desc))

    redis_connection = Redis.new(url: Rails.configuration.x.redis_url)
    redis_connection.hset(redis_key, page_index, rows.to_json)
    redis_connection.expire(redis_key, 1.week)
  ensure
    redis_connection&.close
  end
end
