class Agent::RdvInvitationPolicy < ApplicationPolicy
  alias current_agent pundit_user
  alias rdv_invitation record

  def create?
    same_agent? && can_show_lieu? && can_show_user? && can_show_motif?
  end

  alias new? create?
  alias show? create?

  private

  def same_agent?
    current_agent == rdv_invitation.inviting_agent
  end

  def can_show_lieu?
    rdv_invitation.lieu.blank? || Agent::LieuPolicy.new(current_agent, rdv_invitation.lieu).show?
  end

  def can_show_user?
    Agent::UserPolicy.new(AgentOrganisationContext.new(current_agent, rdv_invitation.organisation), rdv_invitation.user).show?
  end

  def can_show_motif?
    Agent::MotifPolicy.new(current_agent, rdv_invitation.motif).show?
  end
end
