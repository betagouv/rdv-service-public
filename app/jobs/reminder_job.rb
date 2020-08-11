class ReminderJob < ApplicationJob
  queue_as :cron

  def perform(*_args)
    Rdv.not_cancelled.day_after_tomorrow.each do |rdv|
      Notifications::Rdv::RdvUpcomingReminderService.perform_with(rdv)
    end
  end
end
