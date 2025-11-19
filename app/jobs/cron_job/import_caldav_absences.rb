class CronJob::ImportCaldavAbsences < CronJob
  def perform
    Agent.where.not(caldav_agenda_url: nil).each do |agent|
      Caldav::ImportAbsencesFromCaldavJob.perform_later(agent.id)
    end
  end
end
