class Agent::WebhookEndpointPolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def territorial_admin?
    self.class.allowed_to_manage_webhooks_in?(record.organisation.territory, pundit_user)
  end

  def self.allowed_to_manage_webhooks_in?(territory, agent)
    agent.territorial_admin_in?(territory)
  end

  def new?
    pundit_user.territorial_roles.any?
  end

  alias create? territorial_admin?
  alias edit? territorial_admin?
  alias update? territorial_admin?
  alias destroy? territorial_admin?

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    def resolve
      WebhookEndpoint.where(organisation: [pundit_user.organisations])
    end
  end
end
