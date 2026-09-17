class Admin::RdvInvitationsController < AgentAuthController
  def new
    @rdv_invitation = RdvInvitation.new(params.permit(:user_id, :motif_id, :lieu_id).merge(inviting_agent: current_agent))
    authorize(@rdv_invitation, policy_class: Agent::RdvInvitationPolicy)
  end

  def create
    @rdv_invitation = RdvInvitation.new(create_params.merge(inviting_agent: current_agent))
    authorize(@rdv_invitation, policy_class: Agent::RdvInvitationPolicy)

    if @rdv_invitation.save
      Users::RdvInvitationMailer.with(rdv_invitation: @rdv_invitation).new_invitation.deliver_later

      flash[:success] = "Invitation envoyée"
      redirect_to show_confirmation_admin_organisation_rdv_invitation_path(current_organisation, @rdv_invitation)
    else
      render :new
    end
  end

  def show_confirmation
    set_invitation(:show?)
  end

  def show
    set_invitation
  end

  def cancel
    set_invitation(:update?)
    @rdv_invitation.update!(cancelled: true)
    redirect_to admin_organisation_rdv_invitation_path(current_organisation, @rdv_invitation)
  end

  private

  def set_invitation(action_name = nil)
    @rdv_invitation = current_organisation.rdv_invitations.find(params[:id])
    authorize(@rdv_invitation, action_name, policy_class: Agent::RdvInvitationPolicy)
  end

  def create_params
    params.require(:rdv_invitation).permit(:user_id, :motif_id, :lieu_id)
  end

  def pundit_user
    current_agent
  end
end
