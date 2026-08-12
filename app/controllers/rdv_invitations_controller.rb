class RdvInvitationsController < ApplicationController
  layout "application_base"

  def show
    @rdv_invitation = RdvInvitation.find_by(token: params[:rdv_invitation_token])

    if @rdv_invitation.rdv.blank?
      @creneau_selection_service = CreneauWizardForUsers::Steps::CreneauSelection.build_from_invitation(
        motif: @rdv_invitation.motif, lieu: @rdv_invitation.lieu, user: @rdv_invitation.user, start_date: params[:date].presence&.to_date || Time.zone.today,
        invitation_token: @rdv_invitation.token
      )
    else

      rdv = @rdv_invitation.rdv
      redirect_to users_rdv_path(rdv, invitation_token: rdv.participations.find_by(user_id: @rdv_invitation.user_id).restricted_auth_token)
    end
  end

  def create_rdv
    @rdv_invitation = RdvInvitation.find_by(invitation_token: params[:rdv_invitation_token])

    # TODO: décider de ce qu'on fait des motifs ants, puisqu'on ne va pas gérer le multi-participant ici
    creneau = CreneauxSearch::ForUser.creneau_for(
      motif: @rdv_invitation.motif,
      lieu: @rdv_invitation.lieu,
      user: @rdv_invitation.user,
      starts_at: Time.zone.parse(params[:starts_at])
    )

    # TODO: vérifier qu'on ne permet pas les rendez-vous collectifs
    if @rdv_invitation.create_rdv_and_notify(starts_at:, agent: creneau.agent)
      flash[:success] = t("users.rdvs.create.rdv_confirmed")

      rdv = @rdv_invitation.rdv

      # TODO: remettre ça en commun avec UserAuthController
      cookies.encrypted[:"user_name_initials_verified_#{@rdv_invitation.user_id}"] = {
        value: true, expires: 10.minutes.from_now,
      }

      redirect_to users_rdv_path(@rdv_invitation.rdv, invitation_token: rdv.participations.find_by(user_id: @rdv_invitation.user_id).restricted_auth_token)
    else

      flash[:error] = @rdv_invitation.errors.full_messages
      redirect_to rdv_invitations_path(@rdv_invitation.token)
    end
  end
end
