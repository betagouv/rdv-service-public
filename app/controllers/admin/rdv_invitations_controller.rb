class Admin::RdvInvitationsController < AgentAuthController
  def new
    @rdv_invitation = RdvInvitation.new(params.permit(:user_id, :motif_id, :lieu_id).merge(inviting_agent: current_agent))
    authorize(@rdv_invitation, policy_class: Agent::RdvInvitationPolicy)
  end

  def create_user
    @user = User.new(params.require(:user).permit(:first_name, :last_name, :email, :phone_number))
    @user.user_profiles.build(organisation: current_organisation)

    authorize(@user, :create?, policy_class: Agent::UserPolicy)
    if @user.save
      redirect_to new_admin_organisation_rdv_invitation_path(motif_id: params[:motif_id], user_id: @user.id)
    else
      @rdv_invitation = RdvInvitation.new(params.permit(:motif_id, :lieu_id).merge(inviting_agent: current_agent))
      authorize(@rdv_invitation, :new?, policy_class: Agent::RdvInvitationPolicy)
      render :new
    end
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
    @rdv_invitation = current_organisation.rdv_invitations.find(params[:id])
    authorize(@rdv_invitation, :show?, policy_class: Agent::RdvInvitationPolicy)
  end

  def show
    @rdv_invitation = current_organisation.rdv_invitations.find(params[:id])
    authorize(@rdv_invitation, policy_class: Agent::RdvInvitationPolicy)
  end

  private

  def create_params
    params.require(:rdv_invitation).permit(:user_id, :motif_id, :lieu_id)
  end

  def pundit_user
    current_agent
  end
end
