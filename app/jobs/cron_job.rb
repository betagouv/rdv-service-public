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

  class DestroyOldRdvsAndInactiveAccountsJob < CronJob
    def perform
      two_years_ago = 2.years.ago

      Receipt.where(created_at: ..two_years_ago).destroy_all

      Rdv.where(starts_at: ..two_years_ago).each do |rdv|
        rdv.webhook_reason = "rgpd"
        rdv.destroy
      end

      # La suppression d'utilisateurs inactifs a besoin que les vieux rdv soient supprimés
      # On utilise la même date limite pour éviter une race condition liée au temps d'exécution du premier job
      DestroyInactiveUsers.perform_later(two_years_ago)
      WarnInactiveAgentsOfAccountDeletion.perform_later(two_years_ago)
      DestroyInactiveAgents.perform_later(two_years_ago)
    end
  end

  class DestroyInactiveUsers < CronJob
    def perform(date_limit)
      old_users_without_rdvs = User.where("users.created_at < ?", date_limit).where.missing(:participations)
        .where("users.rdv_invitation_token_updated_at is null or users.rdv_invitation_token_updated_at < ?", date_limit)

      old_users_without_rdvs_or_relatives = old_users_without_rdvs.joins("left outer join users as relatives on users.id = relatives.responsible_id").where(relatives: { id: nil })

      old_users_without_rdvs_or_relatives.find_each do |user|
        # les referent_assignations sont détruites par le dependent: :destroy, ici il suffit donc de les flagger
        user.referent_assignations.each { |referent_assignation| referent_assignation.webhook_reason = "rgpd" }
        user.user_profiles.each do |profile|
          profile.webhook_reason = "rgpd"
          profile.destroy
        end
        user.reload
        user.destroy # l'utilisateur n'a plus d'orgnisation liée, donc aucun webhook ne sera envoyé
      end
    end
  end

  class InactiveAgentsJob < CronJob
    protected

    def inactive_agents(date_limit)
      agents_without_rdvs = Agent.where.missing(:agents_rdvs)

      agents_without_rdvs.where("created_at < ?", date_limit).where("last_sign_in_at IS NULL OR last_sign_in_at < ?", date_limit)
    end
  end

  class WarnInactiveAgentsOfAccountDeletion < InactiveAgentsJob
    def perform(date_limit)
      inactive_agents_without_recent_warning = inactive_agents(date_limit - 30.days)
        .where("account_deletion_warning_sent_at IS NULL OR account_deletion_warning_sent_at < ?", date_limit)

      inactive_agents_without_recent_warning.find_each do |agent|
        Agents::AccountDeletionMailer.with(agent: agent).upcoming_deletion_warning.deliver_later
        # Cet update doit réussir même si l'agent n'est pas valide, et ne nécessite pas les callbacks (comme les webhooks), d'où le update_columns
        agent.update_columns(account_deletion_warning_sent_at: Time.zone.now) # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end

  class DestroyInactiveAgents < InactiveAgentsJob
    def perform(date_limit)
      inactive_agents(date_limit).where("account_deletion_warning_sent_at < ?", 30.days.ago).find_each do |agent|
        agent.webhook_reason = "rgpd"
        agent.destroy
      end
    end
  end

  class DestroyOldPlageOuvertureJob < CronJob
    def perform
      po_exceptionnelle_closed_since_1_year = PlageOuverture.where(recurrence: nil).where(first_day: ..1.year.ago)
      po_recurrent_closed_since_1_year = PlageOuverture.where(recurrence_ends_at: ..1.year.ago)
      po_exceptionnelle_closed_since_1_year.or(po_recurrent_closed_since_1_year).each do |po|
        po.webhook_reason = "rgpd"
        po.destroy
      end
    end
  end

  class AnonymizeOldReceipts < CronJob
    def perform
      Anonymizer.anonymize_records!(Receipt.where("created_at < ?", 6.months.ago))
    end
  end

  class DestroyOldApiCalls < CronJob
    def perform
      ApiCall.where("received_at < ?", 1.year.ago).delete_all
    end
  end

  class DestroyRedisWaitingRoomKeys < CronJob
    def perform
      Rdv.reset_user_in_waiting_room!
    end
  end

  class WarnAboutExpiringAzureAppSecrets < CronJob
    def perform
      application_key_expiration_date = Date.new(2025, 1, 10)
      key_refresh_url = "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Credentials/appId/ad7b4a46-0051-47b6-bf31-713aa849e5d4/isMSAApp~/true"

      if 2.months.from_now > application_key_expiration_date
        error_message = <<~ERROR
          Le secret de client de l'application d'oauth Microsoft expire dans moins de 2 mois.
          Pour que la synchro Outlook continue de fonctionner, vous générez un nouveau secret via #{key_refresh_url}
          Les identifiants pour se connecter sont dans Passbolt sous le nom "Compte Dev pour Oauth Microsoft".
          Vous devrez ensuite mettre la valeur du secret dans la variable d'env AZURE_APPLICATION_CLIENT_SECRET, et mettre à jour la date de cet avertissement.
        ERROR
        Sentry.capture_message(error_message, fingerprint: ["WarnAboutExpiringAzureAppSecrets"])
      end
    end
  end
end
