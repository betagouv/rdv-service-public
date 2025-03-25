class ExportJob < ApplicationJob
  queue_as :latency_whenever

  private

  def redis_key(export_id)
    "ExportJob-#{export_id}"
  end
end
