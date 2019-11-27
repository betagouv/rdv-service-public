class ReminderJob < ApplicationJob
  queue_as :cron

  def perform(*_args)
    Rdv.tomorrow.each { |rdv| rdv.send_reminder if rdv.notify? }
  end
end
