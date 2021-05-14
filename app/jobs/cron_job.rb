# frozen_string_literal: true

class CronJob < ApplicationJob
  # Cron jobs superclass
  # See https://github.com/codez/delayed_cron_job#custom-cronjob-superclass
  # It mostly ensures there is only one single scheduled job of each cron job class.
  queue_as :cron

  class_attribute :cron_expression

  class << self
    def schedule
      set(cron: cron_expression).perform_later unless scheduled?
    end

    def remove
      delayed_job.destroy if scheduled?
    end

    def scheduled?
      delayed_job.present?
    end

    def delayed_job
      Delayed::Job
        .where("handler LIKE ?", "%job_class: #{name}%")
        .first
    end
  end

  ## Actual Cron Jobs
  #
  class FileAttenteJob < CronJob
    # Every 10 minutes, from 9:00 to 18:00
    self.cron_expression = "0/10 9,10,11,12,13,14,15,16,17,18 * * *"

    def perform
      FileAttente.send_notifications
    end
  end

  class ReminderJob < CronJob
    # At 9:00 every day
    self.cron_expression = "0 9 * * *"

    def perform
      Rdv.not_cancelled.day_after_tomorrow.each do |rdv|
        Notifications::Rdv::RdvUpcomingReminderService.perform_with(rdv)
      end
    end
  end

  class UpdatePlageOuverturesExpirationsJob < CronJob
    # At 1:00 every day
    self.cron_expression = "0 1 * * *"

    def perform
      PlageOuverture.where(expired_cached: false).each(&:refresh_plage_ouverture_expired_cached)
    end
  end

  class SendRdvEventsStatsMailJob < CronJob
    # At 12:00 every day
    self.cron_expression = "0 12 * * *"

    def perform
      Admins::SystemMailer.rdv_events_stats.deliver_later
    end
  end
end
