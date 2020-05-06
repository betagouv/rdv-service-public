class ReminderJob < ApplicationJob
  queue_as :cron

  def perform(*_args)
    Rdv.active.day_after_tomorrow.each do |rdv|
      Notifications::Rdv::RdvUpcomingReminderService.perform_with(rdv)
    end
  end
end
