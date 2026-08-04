class Caldav::BaseJob < ApplicationJob
  around_perform do |_job, block|
    block.call
  rescue Calendav::RequestError => e
    # Cela permet d'identifier singulièrement l'erreur selon le code HTTP de la réponse
    Sentry.get_current_scope.set_fingerprint(["{{default}}", "Calendav::RequestError", e.response.status.code.to_s])
    raise
  end
end
