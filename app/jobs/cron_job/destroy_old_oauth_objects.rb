class CronJob::DestroyOldOauthObjects < CronJob
  def perform
    Doorkeeper::AccessGrant.where("created_at < ?", 24.hours.ago).delete_all
    Doorkeeper::AccessToken.where("created_at < ?", 30.days.ago).delete_all
  end
end
