# frozen_string_literal: true

class Agent::WebhookEndpointPolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def agent_territory_admin?
    current_agent.territorial_admin_in?(record.organisation.territory)
  end

  alias create? agent_territory_admin?
  alias update? agent_territory_admin?
  alias edit? agent_territory_admin?
  alias new? agent_territory_admin?
  alias versions? agent_territory_admin?

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    def resolve
      WebhookEndpoint.where(organisation: [current_agent.organisations])
    end
  end
end
