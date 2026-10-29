class CronJob::ImportCaldavAbsences < CronJob
  def perform
    CaldavConfig.order(:id).find_each.with_index do |caldav_config, index|
      wait_until = (index * 2).seconds.from_now
      Caldav::ImportAbsencesFromCaldavJob.set(wait_until:).perform_later(caldav_config.agent_id)
    end
  end
end
