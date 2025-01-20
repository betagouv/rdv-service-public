class JobsNotScheduledCorrectly < StandardError; end

class HealthController < ApplicationController
  def db_connection
    Territory.count # cette ligne raisera en cas de problème de connexion
    render status: :ok, plain: "health OK"
  end

  def jobs_queues
    counts1 = compute_enqueued_jobs_count_by_queue
    queues_with_many_jobs = counts1.select { |_queue, count| count > 10 }
    return render(status: :ok, json: {}) if queues_with_many_jobs.none?

    sleep(5) # leave some time for some jobs to be performed
    counts2 = compute_enqueued_jobs_count_by_queue
    congested_queues = queues_with_many_jobs.select { |queue, count1| counts2.fetch(queue, 0) >= count1 }.keys

    return render(status: :service_unavailable, json: { congested_queues: }) if congested_queues

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

  private

  def compute_enqueued_jobs_count_by_queue
    GoodJob::Job
      .group(:queue_name)
      .where("scheduled_at < ?", Time.zone.now)
      .where(finished_at: nil)
      .count
  end
end
