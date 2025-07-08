class JobsNotScheduledCorrectly < StandardError; end
class JobsCongestionError < StandardError; end

class HealthController < ApplicationController
  def db_connection
    Territory.count # cette ligne raisera en cas de problème de connexion
    render status: :ok, plain: "health OK"
  end

  def jobs_queues
    queues = [
      { name: "latency_30s", late_jobs_threshold: 10, delay: 30.seconds },
      { name: "latency_5m", late_jobs_threshold: 10, delay: 5.minutes },
      { name: "latency_whenever", late_jobs_threshold: 10, delay: 1.hour },
    ].map do |queue|
      late_jobs = GoodJob::Job
        .where(finished_at: nil) # finished_at is set upon success or final failure
        .where(queue_name: queue[:name])
        .where("scheduled_at < ?", Time.zone.now - queue[:delay]) # scheduled_at is updated at each retry
      late_jobs_by_class = late_jobs
        .group(:job_class)
        .count
        .to_h do |job_class, count|
          earliest_scheduled_at = late_jobs.where(job_class:).order(:scheduled_at).first.scheduled_at
          [job_class, { count:, earliest_scheduled_at: }]
        end
      queue.merge(late_jobs_by_class:)
    end
    congested_queues = queues.select { _1[:late_jobs_by_class].present? }

    if congested_queues.any?
      Sentry.set_context(:congested_queues, { congested_queues: })
      Sentry.capture_exception(JobsCongestionError.new(congested_queues.pluck(:name).to_sentence))

      return render(status: :service_unavailable, json: { congested_queues: })
    end

    render(status: :ok, json: {})
  end

  def jobs_scheduled
    time_range = (1.hour.ago..2.minutes.ago) # petit délai pour laisser le temps au scheduler d’enqueue les jobs
    jobs_ok, jobs_missed = Rails.configuration.good_job.cron.map do |cron_key, cron_config|
      expected_enqueued_ats = CronMonitor.expected_enqueued_ats(cron_config[:cron], time_range).map(&:to_s)
      # on utilise cron_key et cron_at pour utiliser l’index existant. cron_at ~= enqueued_at
      actual_enqueued_ats = GoodJob::Job.where(cron_key:, cron_at: (1.hour.ago..Time.zone.now)).pluck(:cron_at).map(&:to_s)
      missed_jobs_count = expected_enqueued_ats.count - actual_enqueued_ats.count

      cron_config.merge(missed_jobs_count:, expected_enqueued_ats:, actual_enqueued_ats:)
    end.partition { _1[:missed_jobs_count] <= 0 }

    context = { time_range_start: time_range.begin, time_range_end: time_range.end, jobs_ok:, jobs_missed: }
    if jobs_missed.any?
      Sentry.set_context("jobs_missed", context.except(:jobs_ok)) # pour alléger le contexte sentry
      Sentry.capture_exception(JobsNotScheduledCorrectly.new)
      render status: :service_unavailable, json: context
    else
      render status: :ok, json: context
    end
  end
end
