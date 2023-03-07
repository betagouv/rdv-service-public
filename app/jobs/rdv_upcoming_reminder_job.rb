# frozen_string_literal: true

class RdvUpcomingReminderJob < ApplicationJob
  queue_as :reminders

  def perform(rdv)
    Notifiers::RdvUpcomingReminder.perform_with(rdv, nil)
  end
end
