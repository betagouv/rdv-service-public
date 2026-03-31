Rails.application.configure do
  config.active_job.default_priority = 0

  config.good_job.preserve_job_records = true
  config.cleanup_preserved_jobs_before_seconds_ago = ENV.fetch("GOOD_JOB_CLEANUP_PRESERVED_JOBS_BEFORE_SECONDS_AGO", 1.week.in_seconds)
  config.good_job.on_thread_error = ->(exception) { Sentry.capture_exception(exception) } # this is never called !
  config.good_job.execution_mode = :external
  config.good_job.queues = "latency_30s:1; latency_5m,latency_30s:2; *:2"
  config.good_job.shutdown_timeout = 25 # seconds

  # See https://github.com/bensheldon/good_job/pull/883
  config.good_job.smaller_number_is_higher_priority = true

  # Enable cron in this process; e.g. only run on the first Scalingo worker process
  config.good_job.enable_cron = ENV["CONTAINER"] == "jobs-1"
  # To locally run GoodJob with cron enabled, run: `GOOD_JOB_ENABLE_CRON=1 bundle exec good_job start`

  # Rappel des changements d'heure :
  # - au passage à l'heure d'hiver, on passe deux fois sur l'heure entre 02:00 et 02:59
  # - au passage à l'heure d'été, on passe de 01:59 à 03:00
  # Il est donc dangereux de déclarer un cron entre 02:00 et 02:59.
  config.good_job.cron = {
    file_attente_job: {
      cron: "0/10 9,10,11,12,13,14,15,16,17,18 * * * Europe/Paris", # Every 10 minutes, from 9:00 to 18:00
      class: "CronJob::FileAttenteJob",
    },

    # Ce job doit impérativement s'exécuter exactement une fois dans la journée,
    # il schedule les envois des notifs des RDVs ayant lieu le surlendemain.
    reminder_job: {
      cron: "every day at 03:00 Europe/Paris",
      class: "CronJob::ReminderJob",
    },

    # Pré-calcul d'index : pas essentiel mais idéalement quotidien
    update_expirations_job: {
      cron: "every day at 03:30 Europe/Paris",
      class: "CronJob::UpdateExpirationsJob",
    },

    update_rdv_calculator_index: {
      cron: "every day at 03:40 Europe/Paris",
      class: "CronJob::UpdateRdvCalculatorIndexJob",
    },

    # Reset de la liste d'usagers en salle d'attente, à vider chaque soir
    destroy_redis_waiting_room_keys: {
      cron: "every day at 21:30 Europe/Paris",
      class: "CronJob::DestroyRedisWaitingRoomKeys",
    },

    destroy_expired_export_file_blobs: {
      cron: "every day at 00:15 Europe/Paris",
      class: "CronJob::DestroyExpiredExportFileBlobs",
    },

    destroy_old_rdvs_and_inactive_users_job: {
      cron: "every day at 22:00 Europe/Paris",
      class: "CronJob::DestroyOldRdvsAndInactiveAccountsJob",
    },
    destroy_old_plage_ouverture_job: {
      cron: "every day at 22:30 Europe/Paris",
      class: "CronJob::DestroyOldPlageOuvertureJob",
    },
    destroy_old_absences_job: {
      cron: "every day at 22:35 Europe/Paris",
      class: "CronJob::DestroyOldAbsencesJob",
    },
    destroy_old_oauth_objects: {
      cron: "every day at 22:45 Europe/Paris",
      class: "CronJob::DestroyOldOauthObjects",
    },
    destroy_old_versions: {
      cron: "every day at 23:00 Europe/Paris",
      class: "CronJob::DestroyOldVersions",
    },
    destroy_old_api_calls: {
      cron: "every day at 23:30 Europe/Paris",
      class: "CronJob::DestroyOldApiCalls",
    },
    anonymize_old_receipts: {
      cron: "every day at 23:45 Europe/Paris",
      class: "CronJob::AnonymizeOldReceipts",
    },
    warn_about_expiring_azure_app_secrets: {
      cron: "every day at 10:00 Europe/Paris",
      class: "CronJob::WarnAboutExpiringAzureAppSecrets",
    },
    synchronize_crm: {
      cron: "every day at 08:00 Europe/Paris",
      class: "CronJob::SynchronizeCrm",
    },
    ign_health_check: {
      cron: "every minute",
      class: "CronJob::IGNHealthCheckJob",
    },
    notify_sms_factor_low_credits: {
      cron: "every day at 08:00 Europe/Paris",
      class: "CronJob::NotifySmsFactorLowCredits",
    },
    send_mattermost_notifications_for_zammad_tickets: {
      cron: "every weekday at 10:15 Europe/Paris",
      class: "CronJob::SendMattermostNotificationsForZammadTicketsJob",
    },
    refresh_blog_posts_from_docs: {
      cron: "every day at 06:00 Europe/Paris",
      class: "CronJob::RefreshBlogPostsFromDocsJob",
    },
    refresh_carto_anct_stats: {
      cron: "every day at 06:30 Europe/Paris",
      class: "CronJob::RefreshCartoANCTStatsJob",
    },
    refresh_cached_stats: {
      cron: "every day at 08:00 Europe/Paris",
      class: "CronJob::RefreshCachedStats::EnqueueAllKeysJob",
    },
    import_caldav_absences: {
      cron: "every 15 minutes",
      class: "CronJob::ImportCaldavAbsences",
    },
    destroy_login_codes: {
      cron: "every day at 05:00 Europe/Paris",
      class: "CronJob::DestroyLoginCodesJob",
    },
    refresh_agents_sensitive_account: {
      cron: "every day at 04:00 Europe/Paris",
      class: "CronJob::RefreshAgentsSensitiveAccountJob",
    },
  }
end
