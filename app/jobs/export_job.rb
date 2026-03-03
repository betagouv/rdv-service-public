class ExportJob < ApplicationJob
  queue_as :latency_whenever

  # Les exports ne sont pas urgents, et ils sont longs à exécuter,
  # donc il est raisonnable qu'ils laissent la priorité aux autres jobs.
  queue_with_priority 10
end
