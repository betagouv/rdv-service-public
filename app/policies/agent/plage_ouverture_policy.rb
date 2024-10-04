class Agent::PlageOuverturePolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def show?
    same_agent_or_has_access?
  end
  alias versions? show?

  def update?
    same_agent_or_has_access?
  end
  alias new? update?
  alias create? update?
  alias edit? update?
  alias destroy? update?

  private

  def same_agent_or_has_access?
    return true if @record.agent == current_agent

    case current_agent.access_level_in(@record.organisation)
    when AgentRole::ACCESS_LEVEL_ADMIN
      true
    when AgentRole::ACCESS_LEVEL_BASIC
      same_service? || current_agent.secretaire?
    else
      false
    end
  end

  def same_service?
    @record.agent.confrere_of?(current_agent)
  end

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    def resolve
      my_plages = PlageOuverture.where(agent: current_agent)
      if current_agent.secretaire?
        plages_of_all_my_orgs = PlageOuverture.where(organisation: current_agent.organisations)
        scope.where_id_in_subqueries([my_plages, plages_of_all_my_orgs])
      else
        plages_of_my_admin_orgs = PlageOuverture.where(organisation: current_agent.admin_orgs)
        plages_of_confreres_in_my_basic_orgs = PlageOuverture.where(organisation: current_agent.basic_orgs)
          .joins(:agent).merge(current_agent.confreres)
        scope.where_id_in_subqueries([my_plages, plages_of_my_admin_orgs, plages_of_confreres_in_my_basic_orgs])
      end
    end
  end

  class DepartementScope < Scope
  end
end
