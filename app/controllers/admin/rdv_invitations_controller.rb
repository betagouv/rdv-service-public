class Admin::RdvInvitationsController < AgentAuthController
  def new
    @rdv_invitation = RdvInvitation.new(inviting_agent: current_agent)
    authorize(@rdv_invitation, policy_class: Agent::RdvInvitationPolicy)
  end

  def create
    create_params = params.require(:rdv_invitation).permit(:user_id)

    @rdv_invitation = RdvInvitation.new(create_params.merge(inviting_agent: current_agent))
    authorize(@rdv_invitation, policy_class: Agent::RdvInvitationPolicy)

    user = @rdv_invitation.user

    if user.blank?
      user = User.new(params.require(:rdv_invitation).require(:user).permit(:first_name, :last_name, :email, :phone_number))
      user.user_profiles.build(organisation: current_organisation)

      authorize(user, :create?, policy_class: Agent::UserPolicy)

      user.save!
      @rdv_invitation.user_id = user.id
    end

    if @rdv_invitation.save!
      redirect_to edit_motif_admin_organisation_rdv_invitation_path(current_organisation, @rdv_invitation)
    else
      render :new
    end
  end

  def edit_user
    set_and_authorize_invitation(:edit?)
    render :new
  end

  def edit_motif
    set_and_authorize_invitation(:edit?)
    @motifs = Motif.individuel.available_motifs_for_organisation_and_agent(current_organisation, current_agent).ordered_by_name
  end

  def update_motif
    set_and_authorize_invitation(:update?)

    rdv_invitation_params = params.require(:rdv_invitation).permit(:motif_id)

    @rdv_invitation.assign_attributes(rdv_invitation_params)
    @rdv_invitation.lieu_id = nil # Pour éviter de garder un lieu si on passe à un motif qui n'est pas sur place

    authorize(@rdv_invitation, :edit?, policy_class: Agent::RdvInvitationPolicy)

    if @rdv_invitation.save
      redirect_to new_confirmation_admin_organisation_rdv_invitation_path(current_organisation, @rdv_invitation)
    else
      render "edit_motif"
    end
  end

  def new_confirmation
    set_and_authorize_invitation(:edit?)
  end

  def confirm_and_send
    set_and_authorize_invitation(:update?)

    @rdv_invitation.send_invitation!

    flash[:success] = "Invitation envoyée"
    redirect_to show_confirmation_admin_organisation_rdv_invitation_path(current_organisation, @rdv_invitation)
  end

  def show_confirmation
    set_and_authorize_invitation(:show?)
  end

  def show
    set_and_authorize_invitation
  end

  def cancel
    set_and_authorize_invitation(:update?)
    @rdv_invitation.update!(cancelled: true)
    flash[:notice] = "Invitation résiliée"
    redirect_to admin_organisation_rdv_invitation_path(current_organisation, @rdv_invitation)
  end

  private

  def set_and_authorize_invitation(action_name = nil)
    @rdv_invitation = RdvInvitation.find(params[:id])
    authorize(@rdv_invitation, action_name, policy_class: Agent::RdvInvitationPolicy)
  end

  def pundit_user
    current_agent
  end
end
