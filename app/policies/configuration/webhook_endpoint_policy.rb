class Configuration::WebhookEndpointPolicy
  def initialize(context, webhook_endpoint)
    @current_agent = context.agent
    @webhook_endpoint = webhook_endpoint
  end

  def territorial_admin?
    self.class.allowed_to_manage_webhooks_in?(@webhook_endpoint.organisation.territory, @current_agent)
  end

  def self.allowed_to_manage_webhooks_in?(territory, agent)
    agent.territorial_admin_in?(territory)
  end

  alias new? territorial_admin?
  alias create? territorial_admin?
  alias edit? territorial_admin?
  alias update? territorial_admin?
  alias destroy? territorial_admin?

  class Scope
    def initialize(context, _scope)
      @current_territory = context.territory
    end

    def resolve
      WebhookEndpoint.where(organisation: @current_territory.organisations)
    end
  end
end
