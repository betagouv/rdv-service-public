class Admin::RdvInvitationsController < AgentAuthController
  def new
    @rdv_invitation = RdvInvitation.new(inviting_agent: current_agent, motif_id: params[:motif_id], lieu_id: params[:lieu_id], user_id: params[:user_id])

    authorize(@rdv_invitation, policy_class: Agent::RdvInvitationPolicy)
  end

  def create
    @rdv_invitation = RdvInvitation.new(create_params.merge(inviting_agent: current_agent))

    authorize(@rdv_invitation, policy_class: Agent::RdvInvitationPolicy)

    if @rdv_invitation.save
      Users::RdvInvitationMailer.with(rdv_invitation: @rdv_invitation).invitation.deliver_later

      redirect_to admin_organisation_rdv_plan_path(current_organisation, @rdv_invitation)
    else
      render :new
    end
  end

  def show
    @rdv_invitation = RdvInvitation.find(params[:id])
    authorize(@rdv_invitation, policy_class: Agent::RdvInvitationPolicy)
  end

  private

  def create_params
    params.require(:rdv_invitation).permit(:motif_id, :user_id, :lieu_id)
  end

  def pundit_user
    current_agent
  end
end
