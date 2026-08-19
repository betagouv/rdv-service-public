class CronJob::ImportCaldavAbsences < CronJob
  def perform
    CaldavConfig.find_each do |caldav_config|
      Caldav::ImportAbsencesFromCaldavJob.perform_later(caldav_config.agent_id)
    end
  end
end
