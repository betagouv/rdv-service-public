class Agent::AgentPolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def current_agent_or_admin_in_record_organisation?
    current_agent? || admin_in_record_organisation?
  end

  def current_agent?
    record == current_agent
  end

  def admin_in_record_organisation?
    record.organisation_ids.any? { current_agent.admin_in_organisation?(_1) }
  end

  alias show? current_agent_or_admin_in_record_organisation?
  alias edit? current_agent_or_admin_in_record_organisation?
  alias update? current_agent_or_admin_in_record_organisation?
  alias reinvite? current_agent_or_admin_in_record_organisation?
  alias versions? current_agent_or_admin_in_record_organisation?
  alias toggle_displays? current_agent?
  alias link_to_pro_connect? current_agent?

  def destroy?
    # Even admins cannot destroy themselves
    admin_in_record_organisation? && record != current_agent
  end

  def create?
    record.organisation_ids.any? &&
      record.organisation_ids.all? { current_agent.admin_in_organisation?(_1) } # NOTE: on fait ici un all? et pas un any?
  end
  alias new? create?

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    def resolve
      agents = scope.joins(:organisations) # JOINing on :organisations allows us to #merge Organisation scopes

      subqueries = [
        agents.merge(current_agent.agent_accueil_orgs), # agents que je peux voir en tant qu'agent d'accueil
        agents.merge(current_agent.organisations_of_admin_territories), # agents que je peux voir en tant qu'administrateur de territoire
        agents.merge(current_agent.admin_orgs), # agents que je peux voir en tant qu'administrateur d'organisation
        agents.merge(current_agent.basic_orgs).merge(current_agent.confreres), # agents du même service (ou sans services) que je peux voir en tant qu'agent basique
        agents.merge(current_agent.admin_roles_of_basic_orgs), # agents admin des organisations où je suis agent basique
      ]

      scope.where_id_in_subqueries(subqueries)
    end
  end
end
