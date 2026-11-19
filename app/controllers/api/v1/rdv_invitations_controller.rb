class Api::V1::RdvInvitationsController < Api::V1::AgentAuthBaseController
  def index
    rdv_invitations = policy_scope(RdvInvitation, policy_scope_class: Agent::RdvInvitationPolicy::Scope)
      .includes(:lieu, :inviting_agent, motif: :motif_category)

    if params[:user_external_id].present?
      rdv_invitations = rdv_invitations.joins(user: :external_references)
        .where(external_references: { oauth_application: doorkeeper_token&.application, external_id: params[:user_external_id] })
    end

    render_collection(rdv_invitations.order(:id))
  end

  private

  def pundit_user
    current_agent
  end
end
