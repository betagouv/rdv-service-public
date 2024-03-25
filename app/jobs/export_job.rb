class ExportJob < ApplicationJob
  queue_as :exports

  private

  def redis_key(export_id)
    "ExportJob-#{export_id}"
  end

  def log_long_run_to_sentry_after
    5.minutes
  end
end
