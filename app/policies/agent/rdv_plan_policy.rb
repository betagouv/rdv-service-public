class Agent::RdvPlanPolicy < ApplicationPolicy
  def create?
    authorized_lieu && pundit_user == record.planning_agent
  end
  alias edit? create?

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
end
