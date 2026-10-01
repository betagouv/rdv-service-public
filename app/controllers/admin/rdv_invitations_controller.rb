class Admin::RdvInvitationsController < AgentAuthController
  def edit_user
    @rdv_invitation = RdvInvitation.new(inviting_agent: current_agent)
    authorize(@rdv_invitation, :new?, policy_class: Agent::RdvInvitationPolicy)
  end

  def create_user
    user = User.new(params.require(:rdv_invitation).require(:user).permit(:first_name, :last_name, :email, :phone_number))
    user.user_profiles.build(organisation: current_organisation)

    authorize(user, :create?, policy_class: Agent::UserPolicy)

    if user.save
      redirect_to edit_motif_admin_organisation_rdv_invitations_path(current_organisation, user_id: user.id)
    else
      render :new
    end
  end

  def edit_motif
    @rdv_invitation = RdvInvitation.new(inviting_agent: current_agent, user_id: params.require(:user_id))

    authorize(@rdv_invitation, :new?, policy_class: Agent::RdvInvitationPolicy)
    @motifs = Motif.individuel.available_motifs_for_organisation_and_agent(current_organisation, current_agent).ordered_by_name
  end

  def creneaux_preview_frame
    @rdv_invitation = RdvInvitation.new(inviting_agent: current_agent, motif_id: params.require(:motif_id))

    authorize(@rdv_invitation, :new?, policy_class: Agent::RdvInvitationPolicy)
    respond_to do |format|
      format.turbo_stream do
        starting_date = Date.parse(params[:date])
        render "creneaux_preview_frame", locals: {
          creneaux: @rdv_invitation.creneaux_search(starting_date).creneaux,
          current_organisation:,
          rdv_invitation: @rdv_invitation,
          starting_date:,
        }
      end
    end
  end

  def new
    @rdv_invitation = RdvInvitation.new({ inviting_agent: current_agent }.merge(params.permit(:user_id, :motif_id)))
    authorize(@rdv_invitation, policy_class: Agent::RdvInvitationPolicy)
  end

  def create
    rdv_invitation_params = params.require(:rdv_invitation).permit(:user_id, :motif_id)
    @rdv_invitation = RdvInvitation.new({ inviting_agent: current_agent }.merge(rdv_invitation_params))
    authorize(@rdv_invitation, policy_class: Agent::RdvInvitationPolicy)

    if @rdv_invitation.save
      Users::RdvInvitationMailer.with(rdv_invitation: @rdv_invitation).new_invitation.deliver_later

      flash[:success] = "Invitation envoyée"
      redirect_to show_confirmation_admin_organisation_rdv_invitation_path(current_organisation, @rdv_invitation)
    else
      flash.now[:error] = @rdv_invitation.errors.full_messages.join(" ")
      render :new
    end
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
