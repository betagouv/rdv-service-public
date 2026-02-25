class OauthApplication < Doorkeeper::Application
  def self.agent_is_verified_by_an_application?(agent)
    OauthApplication
      .joins(:access_tokens)
      .where(oauth_access_tokens: { resource_owner_id: agent.id })
      .where(grants_autonomous_signup: true)
      .any?
  end
end
