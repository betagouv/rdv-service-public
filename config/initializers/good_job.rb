# frozen_string_literal: true

Rails.application.configure do
  config.active_job.default_priority = 0

  config.good_job.preserve_job_records = true
  config.good_job.on_thread_error = ->(exception) { Sentry.capture_exception(exception) }
  config.good_job.execution_mode = :external
  config.good_job.queues = '*'
  config.good_job.max_threads = 5
  config.good_job.shutdown_timeout = 25 # seconds

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

    # Préchauffage de cache : pas essentiel mais idéalement quotidien
    warm_up_occurrences_cache: {
      cron: "every day at 04:00 Europe/Paris",
      class: "CronJob::WarmUpOccurrencesCache",
    },

    # Reset de la liste d'usagers en salle d'attente, à vider chaque soir
    destroy_redis_waiting_room_keys: {
      cron: "every day at 21:30 Europe/Paris",
      class: "CronJob::DestroyRedisWaitingRoomKeys",
    },

    # Nettoyage de vieille données : pas essentiel mais idéalement quotidien
    destroy_old_rdvs_job: {
      cron: "every day at 22:00 Europe/Paris",
      class: "CronJob::DestroyOldRdvsJob",
    },
    destroy_old_plage_ouverture_job: {
      cron: "every day at 22:30 Europe/Paris",
      class: "CronJob::DestroyOldPlageOuvertureJob",
    },
    destroy_old_versions: {
      cron: "every day at 23:00 Europe/Paris",
      class: "CronJob::DestroyOldVersions",
    },
  }
end
