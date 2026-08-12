class Agent::RdvInvitationPolicy < ApplicationPolicy
  def create?
    pundit_user == record.inviting_agent &&
      Agent::LieuPolicy.new(pundit_user, record.lieu).show? &&
      Agent::UserPolicy.new(AgentOrganisationContext.new(pundit_user, record.organisation), record.user).show? &&
      Agent::MotifPolicy.new(pundit_user, record.motif).show?
  end

  alias new? create?
  alias show? create?

  class Scope < Scope
    def resolve
      scope.where(inviting_agent: pundit_user)
    end
  end
end
