class CronJob::ImportCaldavAbsences < CronJob
  def perform
    CaldavConfig.where.not(caldav_agenda_url: nil).find_each do |caldav_config|
      Caldav::ImportAbsencesFromCaldavJob.perform_later(caldav_config.agent_id)
    end
  end
end
