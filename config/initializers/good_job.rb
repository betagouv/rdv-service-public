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
  config.good_job.enable_cron = ENV["CONTAINER"] == "worker-1"
  # To locally run GoodJob with cron enabled, run: `GOOD_JOB_ENABLE_CRON=1 bundle exec good_job start`

  config.good_job.cron = {
    file_attente_job: {
      cron: "0/10 9,10,11,12,13,14,15,16,17,18 * * *", # Every 10 minutes, from 9:00 to 18:00
      class: "CronJob::FileAttenteJob",
    },
    reminder_job: {
      cron: "0 3 * * *", # At 3:00 every day
      class: "CronJob::ReminderJob",
    },
    update_expirations_job: {
      cron: "0 1 * * *", # At 1:00 every day
      class: "CronJob::UpdateExpirationsJob",
    },
    warm_up_occurrences_cache: {
      cron: "0 23 * * *", # At 23:00 every day
      class: "CronJob::WarmUpOccurrencesCache",
    },
    destroy_old_rdvs_job: {
      cron: "0 2 * * *", # At 2:00 every day
      class: "CronJob::DestroyOldRdvsJob",
    },
    destroy_old_plage_ouverture_job: {
      cron: "0 1 * * *", # At 1:00 every day
      class: "CronJob::DestroyOldPlageOuvertureJob",
    },
    destroy_redis_waiting_room_keys: {
      cron: "0 13 * * *", # At 3:00 every day
      class: "CronJob::DestroyRedisWaitingRoomKeys",
    },
  }
end
