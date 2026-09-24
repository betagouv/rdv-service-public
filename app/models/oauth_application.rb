class OauthApplication < Doorkeeper::Application
  has_paper_trail(only: %w[internal_documentation])

  def self.agent_is_verified_by_an_application?(agent)
    OauthApplication
      .joins(:access_tokens)
      .where(oauth_access_tokens: { resource_owner_id: agent.id })
      .where(grants_autonomous_signup: true)
      .any?
  end
end
