class Agent::RdvPlanPolicy < ApplicationPolicy
  def create?
    authorized_lieu &&
      pundit_user == record.planning_agent &&
      authorized_motif?
  end
  alias edit? create?
  alias update? create?
  alias new? create?

  class Scope < Scope
    def resolve
      scope.where(planning_agent: pundit_user)
    end
  end

  private

  # TODO: ajouter une spec pour ce cas
  def authorized_lieu
    return true unless record.lieu_id

    Agent::LieuPolicy::Scope.new(pundit_user, Lieu.enabled).resolve.find_by(id: record.lieu_id).present?
  end

  def authorized_agent
    return true unless record.rdv_agent

    Agent::AgentPolicy::Scope.new(pundit_user, Agent.active).resolve.find_by(id: record.rdv_agent_id).present?
  end

  def authorized_motif?
    return true if record.motif.blank?

    Agent::MotifPolicy.new(pundit_user, record.motif).show?
  end
end
