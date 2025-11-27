class CronJob < ApplicationJob
  queue_as :latency_whenever

  module MonitorConcern
    extend ActiveSupport::Concern

    included do
      crontab = Rails.configuration.good_job.cron.values.find { _1[:class] == name }&.fetch(:cron)
      if crontab
        # cf https://docs.sentry.io/platforms/ruby/crons/#job-monitoring
        # this will send check in events to Sentry on job start and job end
        # this will also upsert the Cron Monitor config in Sentry
        # this upsert runs together with the check in events in the job runtime
        # NOTE: if you delete a CRON job, you have to manually delete it from Sentry
        include Sentry::Cron::MonitorCheckIns # does nothing until sentry_monitor_check_ins is called
        sentry_monitor_check_ins(
          monitor_config: Sentry::Cron::MonitorConfig.from_crontab(
            Fugit.parse(crontab).to_cron_s.sub(" Europe/Paris", ""),
            timezone: "Europe/Paris"
          )
        )
      end
    end
  end

  class FileAttenteJob < CronJob
    queue_as :latency_30s

    include MonitorConcern

    def perform
      FileAttente.send_notifications
    end
  end

  class ReminderJob < CronJob
    def perform
      Rdv.not_cancelled.day_after_tomorrow.find_each do |rdv|
        run_at = rdv.starts_at - 48.hours
        RdvUpcomingReminderJob.set(wait_until: run_at, queue: :latency_5m).perform_later(rdv)
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

  class UpdateRdvCalculatorIndexJob < CronJob
    def perform
      AgentsRdv.where(calculator_rdv_not_cancelled_and_in_the_future: true)
        .where("calculator_rdv_ends_at < ?", Time.zone.now)
        .update_all(calculator_rdv_not_cancelled_and_in_the_future: false) # rubocop:disable Rails/SkipsModelValidations
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

  class DestroyOldAbsencesJob < CronJob
    def perform
      Absence.where(recurrence: nil).where("end_day < ?", 2.years.ago).find_each(&:destroy)
      Absence.where.not(recurrence: nil).where("recurrence_ends_at < ?", 2.years.ago).find_each(&:destroy)
    end
  end

  class AnonymizeOldReceipts < CronJob
    def perform
      Anonymizer.anonymize_records!("receipts", scope: Receipt.arel_table[:created_at].lt(6.months.ago))
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
      return if ENV["AZURE_APPLICATION_CLIENT_ID"].blank?
      return if ENV["AZURE_SECRET_EXPIRE_DATE"].blank?

      application_key_expiration_date = Date.parse(ENV["AZURE_SECRET_EXPIRE_DATE"])
      key_refresh_url = "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Credentials/appId/#{ENV['AZURE_APPLICATION_CLIENT_ID']}/isMSAApp~/true"

      if 2.months.from_now > application_key_expiration_date
        error_message = <<~ERROR
          Le secret de client de l'application d'oauth Microsoft expire dans moins de 2 mois.
          Pour que la synchro Outlook continue de fonctionner, vous générez un nouveau secret via #{key_refresh_url}
          Les identifiants pour se connecter sont dans Vaultwarden sous le nom "Compte Dev pour Oauth Microsoft".
          Vous devrez ensuite mettre la valeur du secret dans la variable d'env AZURE_APPLICATION_CLIENT_SECRET, et "AZURE_SECRET_EXPIRE_DATE".
        ERROR
        Sentry.capture_message(error_message, fingerprint: ["WarnAboutExpiringAzureAppSecrets"])
      end
    end
  end

  class RefreshBlogPostsFromHeadwayJob < CronJob
    def perform
      headway_html = Net::HTTP.get_response(URI(BlogPost::HEADWAY_URL)).body
      posts = HeadwayParser.extract_posts_from_html(headway_html)
      if posts.any?
        BlogPost.refresh_from_posts(posts)
      else
        raise "no posts found on Headway"
      end
    end
  end
end
