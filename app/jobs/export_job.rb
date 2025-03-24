class ExportJob < ApplicationJob
  queue_as :low_priority

  private

  def redis_key(export_id)
    "ExportJob-#{export_id}"
  end
end
