class RdvUpcomingReminderJob < ApplicationJob
  queue_as :reminders

  class TooLateError < StandardError; end
  discard_on(TooLateError) { |_job, error| Sentry.capture_exception(error) }

  def perform(rdv)
    if rdv.ends_at < Time.zone.now
      raise TooLateError, "Reminder not sent: RDV in the past"
    end

    Notifiers::RdvUpcomingReminder.perform_with(rdv, nil)
  end
end
