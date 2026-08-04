class Caldav::BaseJob < ApplicationJob
  rescue_from Calendav::RequestError do |exception|
    http_status = exception.response.status.code
    # Cela permet d'identifier singulièrement l'erreur selon le code HTTP de la réponse
    Sentry.get_current_scope.set_fingerprint(["{{default}}", "Calendav::RequestError", http_status.to_s])
    Sentry.capture_exception(exception)
    retry_job queue: :latency_whenever
  end
end
