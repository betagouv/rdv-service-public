class HealthController < ApplicationController
  def db_connection
    Territory.count # cette ligne raisera en cas de problème de connexion
    render status: :ok, plain: "health OK"
  end

  def jobs_queues
    stale_processes = GoodJob::Process.all.select(&:stale?)
    return render(status: :service_unavailable, json: { stale_processes: }) if stale_processes.any?

    counts1 = compute_enqueued_jobs_count_by_queue
    queues_with_many_jobs = counts1.select { |_queue, count| count > 10 }
    return render(status: :ok, json: {}) if queues_with_many_jobs.none?

    sleep(5) # leave some time for some jobs to be performed
    counts2 = compute_enqueued_jobs_count_by_queue
    congested_queues = queues_with_many_jobs.select { |queue, count1| counts2.fetch(queue, 0) >= count1 }.keys

    return render(status: :service_unavailable, json: { congested_queues: }) if congested_queues

    render(status: :ok, json: {})
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
