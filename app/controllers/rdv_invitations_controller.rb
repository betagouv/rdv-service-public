class RdvInvitationsController < ApplicationController
  layout "application_base"

  def show
    @rdv_invitation = RdvInvitation.find_by(token: params[:rdv_invitation_token])

    if @rdv_invitation.rdv.present?
      redirect_to users_rdv_path(@rdv_invitation.rdv, invitation_token: restricted_auth_token)
    else
      @creneau_selection_service = CreneauWizardForUsers::Steps::CreneauSelection.build_from_invitation(
        rdv_invitation: @rdv_invitation,
        start_date: params[:date].presence&.to_date || Time.zone.today
      )
    end
  end

  def create_rdv
    @rdv_invitation = RdvInvitation.find_by(token: params[:rdv_invitation_token])

    if @rdv_invitation.create_rdv_and_notify(starts_at: Time.zone.parse(params[:starts_at]))
      flash[:success] = t("users.rdvs.create.rdv_confirmed")

      UserAuthController.set_user_name_initials_verified(cookies, @rdv_invitation.user)

      redirect_to users_rdv_path(@rdv_invitation.rdv, invitation_token: restricted_auth_token)
    else

      flash[:error] = @rdv_invitation.errors.full_messages
      redirect_to rdv_invitations_path(@rdv_invitation.token)
    end
  end

  private

  def restricted_auth_token
    @rdv_invitation.rdv.participations.find_by(user_id: @rdv_invitation.user_id).restricted_auth_token
  end
end
