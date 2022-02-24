# frozen_string_literal: true

class Configuration::WebhookEndpointPolicy
  def initialize(context, agent)
    @context = context
    @agent = agent
  end

  def territorial_admin?
    @context.agent.territorial_admin_in?(@context.territory)
  end

  alias new? territorial_admin?
  alias create? territorial_admin?
  alias edit? territorial_admin?
  alias update? territorial_admin?
  alias destroy? territorial_admin?

  class Scope
    def initialize(context, _scope)
      @context = context
    end

    def resolve
      WebhookEndpoint.where(organisation: @context.territory.organisations)
    end
  end
end
