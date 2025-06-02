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
  config.good_job.cron = JSON.parse(Rails.root.join("config/initializers/good_job_cron.json").read)
end
