class CronJob::DestroyOldOauthObjects < CronJob
  CRON = "every day at 22:45 Europe/Paris".freeze

  def perform
    Doorkeeper::AccessGrant.where("created_at < ?", 24.hours.ago).delete_all
    Doorkeeper::AccessToken.where("created_at < ?", 30.days.ago).delete_all
  end
end
