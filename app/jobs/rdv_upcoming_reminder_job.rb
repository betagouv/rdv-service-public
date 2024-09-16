class RdvUpcomingReminderJob < ApplicationJob
  queue_as :reminders

  # Ces jobs sont enqueued 48 heures avant le début du RDV
  # La stratégie de retries par défaut jusqu’à 8 jours ne convient donc pas
  # Ce retry_on a précédence sur celui du DefaultJobBehaviour
  # Les handlers retry_on et discard_on sont parcourus de bas en haut du code puis en remontant les classes parentes
  # (1..14).map { (_1 ** 4) + (_1 ** 4) * 0.15 }.sum.to_f / 60 / 60 ~= 41 heures
  retry_on StandardError, wait: :exponentially_longer, attempts: 14, priority: DefaultJobBehaviour::PRIORITY_OF_RETRIES

  class TooLateError < StandardError; end

  # La date du RDV peut être modifiée dans le passé entre le moment où le job a été enqueued
  # et son éxecution, ou l’exécution d’un retry. Ce sont des erreurs attendues, on ne veut pas
  # en être notifié sur Sentry
  discard_on(TooLateError)

  discard_on(ActiveJob::DeserializationError) do |job, error|
    # Si le RDV a été supprimé avant l’éxecution du job (ou d’un retry)
    # C’est un comportement attendu, on ne veut pas retry ni être notifié sur Sentry
    next if error.cause.is_a?(ActiveRecord::RecordNotFound)

    # dans le cas encore jamais vu où la désérialisation échouerait pour d’autres raisons
    # il ne sert probablement à rien de retry non plus, mais on aimerait en être notifié
    job.sentry_capture_exception(error)
  end

  def perform(rdv)
    if rdv.ends_at < Time.zone.now
      raise TooLateError, "Reminder not sent: RDV in the past"
    end

    Notifiers::RdvUpcomingReminder.perform_with(rdv, nil)
  end
end
