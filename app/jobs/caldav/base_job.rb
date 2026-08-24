class Caldav::BaseJob < ApplicationJob
  around_perform do |_job, block|
    block.call
  rescue Calendav::RequestError => e
    # On souhaite distinguer les erreurs Caldav par statut HTTP pour
    # améliorer notre visibilité sur les différents types d'erreur.
    Sentry.get_current_scope.set_fingerprint(["{{default}}", "Calendav::RequestError", e.response.status.code.to_s])
    raise
  end
end
