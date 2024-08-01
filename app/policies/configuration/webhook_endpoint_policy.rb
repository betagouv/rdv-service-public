class Configuration::WebhookEndpointPolicy
  def initialize(context, webhook_endpoint)
    @current_agent = context.agent
    @webhook_endpoint = webhook_endpoint
  end

  class Scope
    def initialize(agent, scope)
      @current_agent = agent
      @scope = scope
    end

    def resolve
      @scope.joins(:organisation).where(organisations: { territory_id: @current_agent.territorial_roles.select(:territory_id) })
    end
  end
end
