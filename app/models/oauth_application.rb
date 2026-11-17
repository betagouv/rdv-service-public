class OauthApplication < Doorkeeper::Application
  has_paper_trail(only: %w[name redirect_uri grant_type agent_id internal_documentation])

  belongs_to :agent, optional: true

  enum :grant_type, { authorization_code: "authorization_code", client_credentials: "client_credentials" }, default: "authorization_code"

  validates :agent, presence: true, if: :client_credentials?
  validates :redirect_uri, presence: true, if: :authorization_code?

  def self.agent_is_verified_by_an_application?(agent)
    OauthApplication
      .joins(:access_tokens)
      .where(oauth_access_tokens: { resource_owner_id: agent.id })
      .where(grants_autonomous_signup: true)
      .any?
  end
end
