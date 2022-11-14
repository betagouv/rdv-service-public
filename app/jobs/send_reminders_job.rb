# frozen_string_literal: true

class SendRemindersJob < ApplicationJob
  # Don't retry on exception, because error is likely to be internal
  discard_on StandardError do |_job, exception|
    Sentry.capture_exception(exception)
  end

  def perform(rdv)
    Notifiers::RdvUpcomingReminder.perform_with(rdv, nil)
  end
end
