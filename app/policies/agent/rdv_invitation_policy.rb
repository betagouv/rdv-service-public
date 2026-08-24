class Agent::RdvInvitationPolicy < ApplicationPolicy
  def create?
    pundit_user == record.inviting_agent &&
      (record.lieu_id.blank? || Agent::LieuPolicy.new(pundit_user, record.lieu).show?) &&
      Agent::UserPolicy.new(AgentOrganisationContext.new(pundit_user, record.organisation), record.user).show? &&
      Agent::MotifPolicy.new(pundit_user, record.motif).show?
  end

  alias new? create?
  alias show? create?
end
