class CronJob::SyncCaldavAbsences < CronJob
  def perform
    Agent.where.not(caldav_agenda_url: nil).each do |agent|
      Caldav::SyncAbsencesJob.perform_later(agent.id)
    end
  end
end
