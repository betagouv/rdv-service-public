class Agent::WebhookEndpointPolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def allowed_to_manage_webhooks?
    self.class.allowed_to_manage_webhooks_in?(record.organisation.territory, current_agent)
  end

  def self.allowed_to_manage_webhooks_in?(territory, agent)
    agent.territorial_admin_in?(territory)
  end

  def new?
    current_agent.agent_territorial_access_rights.where(territory_admin: true).any?
  end

  alias create? allowed_to_manage_webhooks?
  alias edit? allowed_to_manage_webhooks?
  alias update? allowed_to_manage_webhooks?
  alias destroy? allowed_to_manage_webhooks?
  alias versions? allowed_to_manage_webhooks?

  class Scope
    def initialize(agent, scope)
      @current_agent = agent
      @scope = scope
    end

    def resolve
      @scope.joins(:organisation).where(organisations: { territory_id: @current_agent.agent_territorial_access_rights.where(territory_admin: true).select(:territory_id) })
    end
  end
end
