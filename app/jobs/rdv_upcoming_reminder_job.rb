class RdvUpcomingReminderJob < ApplicationJob
  queue_as :reminders

  # Ces jobs sont enqueued 48 heures avant le début du RDV
  # La stratégie de retries par défaut jusqu’à 8 jours ne convient donc pas
  # Ce retry_on a précédence sur celui du DefaultJobBehaviour
  # Les handlers retry_on et discard_on sont parcourus de bas en haut du code puis en remontant les classes parentes
  retry_on StandardError, wait: 2.hours, attempts: 20, priority: DefaultJobBehaviour::PRIORITY_OF_RETRIES

  class TooLateError < StandardError; end

  discard_on(TooLateError) { |job, error| job.capture_sentry_exception(error) }

  discard_on(ActiveJob::DeserializationError) { |job, error| job.capture_sentry_exception(error) }

  def perform(rdv)
    if rdv.ends_at < Time.zone.now
      raise TooLateError, "Reminder not sent: RDV in the past"
    end

    Notifiers::RdvUpcomingReminder.perform_with(rdv, nil)
  end
end
