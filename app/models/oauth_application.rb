class OauthApplication < Doorkeeper::Application
  belongs_to :default_service, class_name: "Service", optional: true

  def self.agent_is_verified_by_an_application?(agent)
    # Les applications qui ont un default_service_id permettent la création de territoire
    default_service_ids_for(agent).present?
  end

  def self.default_service_ids_for(agent)
    OauthApplication.joins(:access_tokens).where(oauth_access_tokens: { resource_owner_id: agent.id }).pluck(:default_service_id).uniq.compact
  end
end
