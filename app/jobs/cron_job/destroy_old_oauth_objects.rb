class CronJob::DestroyOldOauthObjects < CronJob
  def perform
    Doorkeeper::AccessGrant.where("created_at < ?", 24.hours.ago).delete_all
    old_access_tokens_with_a_more_recent_duplicate.delete_all
  end

  private

  def old_access_tokens_with_a_more_recent_duplicate
    Doorkeeper::AccessToken.where("oauth_access_tokens.created_at < ?", 30.days.ago)
      .joins(<<~SQL.squish
        INNER JOIN oauth_access_tokens as recent_tokens ON
          oauth_access_tokens.resource_owner_id = recent_tokens.resource_owner_id AND
          oauth_access_tokens.application_id = recent_tokens.application_id AND
          oauth_access_tokens.created_at < recent_tokens.created_at
      SQL
            )
  end
end
