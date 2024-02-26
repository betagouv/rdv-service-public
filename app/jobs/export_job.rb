class ExportJob < ApplicationJob
  queue_as :exports

  private

  def redis_key(export_id)
    "ExportJob-#{export_id}"
  end

  def hard_timeout
    5.minutes
  end
end
