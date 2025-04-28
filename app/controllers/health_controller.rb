class JobsNotScheduledCorrectly < StandardError; end

class HealthController < ApplicationController
  def db_connection
    Territory.count # cette ligne raisera en cas de problème de connexion
    render status: :ok, plain: "health OK"
  end

  def jobs_queues
    queues = [
      { name: "latency_30s", pending_jobs_threshold: 10, delay: 30.seconds },
      { name: "latency_5m", pending_jobs_threshold: 10, delay: 5.minutes },
      { name: "latency_whenever", pending_jobs_threshold: 30, delay: nil },
    ]
    queues.each do |queue|
      query = GoodJob::Job.where(executions_count: 0).where(queue_name: queue[:name])
      if queue[:delay]
        query = query.where("scheduled_at < ?", Time.zone.now - (queue[:delay] / 10)) # le petit délai évite de compter les jobs qui viennent d’être enqueued
      end
      queue[:pending_jobs_count] = query.count
    end
    congested_queues = queues.select { _1[:pending_jobs_count] >= _1[:pending_jobs_threshold] }

    return render(status: :service_unavailable, json: { congested_queues: }) if congested_queues.any?

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
