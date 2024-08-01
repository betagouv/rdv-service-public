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

  # On a deux scopes différents qui correspondent à deux choix produits différents :
  # - dans l'api on vérifie que l'agent a un rôle dans l'organisation du webhook
  # - dans l'espace admin, on commence à permettre d'administrer un territoire sans être admin de toutes
  #   ses organisations, ce qui permet de ne pas avoir accès à toutes les données personnelles des
  #   rdvs et de usagers
  #
  #   Il faudra à terme qu'on harmonise ces deux possiblités.
  class ApiScope < Scope
    include CurrentAgentInPolicyConcern

    def resolve
      WebhookEndpoint.where(organisation: [pundit_user.organisations])
    end
  end

  class EspaceAdminScope
    def initialize(agent, scope)
      @current_agent = agent
      @scope = scope
    end

    def resolve
      @scope.joins(:organisation).where(organisations: { territory_id: @current_agent.territorial_roles.select(:territory_id) })
    end
  end
end
