class ReminderJob < ApplicationJob
  queue_as :cron

  def perform(*_args)
    Rdv.tomorrow.each(&:send_reminder)
  end
end
