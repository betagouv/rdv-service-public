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
      update_cron_expression!
    end

    def remove
      delayed_job.destroy if scheduled?
    end

    def scheduled?
      delayed_job.present?
    end

    def update_cron_expression!
      delayed_job.update!(cron: cron_expression)
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
    # At 3:00 every day
    self.cron_expression = "0 3 * * *"

    def perform
      Rdv.not_cancelled.day_after_tomorrow.find_each do |rdv|
        run_at = rdv.starts_at - 48.hours
        RdvUpcomingReminderJob.set(wait_until: run_at).perform_later(rdv)
      end
    end
  end

  class UpdateExpirationsJob < CronJob
    # At 1:00 every day
    self.cron_expression = "0 1 * * *"

    def perform
      [PlageOuverture, Absence].each do |klass|
        klass.not_expired.find_each(&:refresh_expired_cached)
      end
    end
  end

  class WarmUpOccurrencesCache < CronJob
    # At 23:00 every day
    self.cron_expression = "0 23 * * *"

    def perform
      [PlageOuverture, Absence].each do |klass|
        klass.regulieres.not_expired.find_each do |model|
          model.earliest_future_occurrence_time(refresh: true)
        end
      end
    end
  end

  class DestroyOldRdvsJob < CronJob
    # At 2:00 every day
    self.cron_expression = "0 2 * * *"

    def perform
      Rdv.unscoped.where(starts_at: ..2.years.ago).each do |rdv|
        rdv.skip_webhooks = true
        rdv.destroy
      end
    end
  end

  class DestroyOldPlageOuvertureJob < CronJob
    # At 01:00 every day
    self.cron_expression = "0 1 * * *"

    def perform
      po_exceptionnelle_closed_since_1_year = PlageOuverture.where(recurrence: nil).where(first_day: ..1.year.ago)
      po_reccurent_closed_since_1_year = PlageOuverture.where(recurrence_ends_at: ..1.year.ago)
      po_exceptionnelle_closed_since_1_year.or(po_reccurent_closed_since_1_year).each do |po|
        po.skip_webhooks = true
        po.destroy
      end
    end
  end

  class DestroyRedisWaitingRoomKeys < CronJob
    # At 03:00 every day
    self.cron_expression = "0 3 * * *"

    def perform
      Rdv.reset_user_in_waiting_room!
    end
  end
end
