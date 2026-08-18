class Agent::WebhookEndpointPolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def territorial_admin?
    self.class.allowed_to_manage_webhooks_in?(record.organisation.territory, pundit_user)
  end

  def self.allowed_to_manage_webhooks_in?(territory, agent)
    agent.territorial_admin_in?(territory)
  end

  def new?
    pundit_user.agent_territorial_access_rights.where(full_rights: true).any?
  end

  alias create? territorial_admin?
  alias edit? territorial_admin?
  alias update? territorial_admin?
  alias destroy? territorial_admin?
  alias versions? territorial_admin?

  class Scope
    def initialize(agent, scope)
      @current_agent = agent
      @scope = scope
    end

    def resolve
      @scope.joins(:organisation).where(organisations: { territory_id: @current_agent.agent_territorial_access_rights.where(full_rights: true).select(:territory_id) })
    end
  end
end
