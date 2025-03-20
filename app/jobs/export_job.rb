class ExportJob < ApplicationJob
  queue_as :exports

  # Les exports ne sont pas urgents, et ils sont longs à exécuter,
  # donc il est raisonnable qu'ils laissent la priorité aux autres jobs.
  queue_with_priority 10

  private

  def redis_key(export_id)
    "ExportJob-#{export_id}"
  end
end
