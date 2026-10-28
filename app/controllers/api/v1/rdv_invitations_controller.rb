class Api::V1::RdvInvitationsController < Api::V1::AgentAuthBaseController
  def index
    rdv_invitations = policy_scope(RdvInvitation, policy_scope_class: Agent::RdvInvitationPolicy::Scope)

    render_collection(rdv_invitations.order(:id))
  end

  private

  def pundit_user
    current_agent
  end
end
