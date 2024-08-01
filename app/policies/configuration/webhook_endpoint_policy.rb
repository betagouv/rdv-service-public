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
    def initialize(context, scope)
      @current_territory = context.territory
      @current_agent = context.agent
      @scope = scope
    end

    def resolve
      @scope.joins(:organisation).where(organisations: { territory_id: @current_agent.territorial_roles.select(:territory_id) })
    end
  end
end
