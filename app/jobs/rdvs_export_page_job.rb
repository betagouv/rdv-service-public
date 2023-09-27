# frozen_string_literal: true

class RdvsExportPageJob < ExportJob
  def perform(rdv_ids, page_index, redis_key)
    rdvs = Rdv.where(id: rdv_ids).includes(
      :organisation,
      :agents,
      :lieu,
      :receipts,
      :versions_where_event_eq_create,
      motif: :service,
      users: :responsible
    ).order(starts_at: :desc)

    redis_connection = Redis.new(url: Rails.configuration.x.redis_url)

    rows = rdvs.map do |rdv|
      RdvExporter.row_array_from(rdv)
    end

    redis_connection.hset(redis_key, page_index, rows.to_json)
    redis_connection.expire(redis_key, 1.week)
  end
end
