# frozen_string_literal: true

class CronJob < ApplicationJob
  queue_as :cron

  class FileAttenteJob < CronJob
    def perform
      FileAttente.send_notifications
    end
  end

  class ReminderJob < CronJob
    def perform
      Rdv.not_cancelled.day_after_tomorrow.find_each do |rdv|
        run_at = rdv.starts_at - 48.hours
        RdvUpcomingReminderJob.set(wait_until: run_at).perform_later(rdv)
      end
    end
  end

  class UpdateExpirationsJob < CronJob
    def perform
      [PlageOuverture, Absence].each do |klass|
        klass.not_expired.find_each(&:refresh_expired_cached)
      end
    end
  end

  class WarmUpOccurrencesCache < CronJob
    def perform
      [PlageOuverture, Absence].each do |klass|
        klass.regulieres.not_expired.find_each do |model|
          model.earliest_future_occurrence_time(refresh: true)
        end
      end
    end
  end

  class DestroyOldRdvsAndInactiveUsersJob < CronJob
    def perform
      two_years_ago = 2.years.ago
      Rdv.unscoped.where(starts_at: ..two_years_ago).each do |rdv|
        rdv.skip_webhooks = true
        rdv.destroy
      end
      # La suppression d'utilisateurs inactifs a besoin que les vieux rdv soient supprimés
      # On utilise la même date limite pour éviter une race condition liée au temps d'exécution du premier job
      DestroyInactiveUsers.perform_later(two_years_ago)
    end
  end

  class DestroyInactiveUsers < CronJob
    def perform(date_limit)
      old_users_without_rdvs = User.where("users.created_at < ?", date_limit).left_outer_joins(:rdvs_users).where(rdvs_users: { id: nil })

      old_users_without_rdvs_or_relatives = old_users_without_rdvs.joins("left outer join users as relatives on users.id = relatives.responsible_id").where(relatives: { id: nil })

      old_users_without_rdvs_or_relatives.find_each do |user|
        user.user_profiles.each do |profile|
          profile.skip_webhooks = true
          profile.destroy
        end
        user.skip_webhooks = true
        user.destroy
      end
    end
  end

  class DestroyOldPlageOuvertureJob < CronJob
    def perform
      po_exceptionnelle_closed_since_1_year = PlageOuverture.where(recurrence: nil).where(first_day: ..1.year.ago)
      po_recurrent_closed_since_1_year = PlageOuverture.where(recurrence_ends_at: ..1.year.ago)
      po_exceptionnelle_closed_since_1_year.or(po_recurrent_closed_since_1_year).each do |po|
        po.skip_webhooks = true
        po.destroy
      end
    end
  end

  class DestroyOldVersions < CronJob
    def perform
      # Versions are used in RDV exports, and RDVs are currently kept for 2 years.
      PaperTrail::Version.where("created_at < ?", 2.years.ago).delete_all
    end
  end

  class DestroyRedisWaitingRoomKeys < CronJob
    def perform
      Rdv.reset_user_in_waiting_room!
    end
  end
end
