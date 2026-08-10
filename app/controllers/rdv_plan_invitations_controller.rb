class RdvPlanInvitationsController < ApplicationController
  layout "application_base"

  def show
    @rdv_plan = RdvPlan.find_by(invitation_token: params[:rdv_plan_invitation_token])

    if @rdv_plan.rdv.blank?
      start_date = Time.zone.today
      @creneaux_search = CreneauxSearch::ForUser.build_from_rdv_plan(@rdv_plan, date_range: start_date..(start_date + 6.days))
    else

      rdv = @rdv_plan.rdv
      redirect_to users_rdv_path(rdv, invitation_token: rdv.participations.find_by(user_id: @rdv_plan.user_id).restricted_auth_token)
    end
  end

  def create_rdv
    @rdv_plan = RdvPlan.find_by(invitation_token: params[:rdv_plan_invitation_token])

    # TODO: décider de ce qu'on fait des motifs ants, puisqu'on ne va pas gérer le multi-participant ici
    creneau = CreneauxSearch::ForUser.creneau_for(
      motif: @rdv_plan.motif,
      lieu: @rdv_plan.lieu,
      user: @rdv_plan.user,
      starts_at: Time.zone.parse(params[:starts_at])
    )

    if creneau.blank?
      flash[:error] = "Ce créneau n'est plus disponible. Veuillez en sélectionner un autre."
      redirect_to rdv_plan_invitations_path(@rdv_plan.invitation_token) and return
    end

    @rdv_plan.update!(starts_at: params[:starts_at], rdv_agent: creneau.agent, lieu_id: creneau.lieu_id)

    # TODO: vérifier qu'on ne permet pas les rendez-vous collectifs
    rdv = @rdv_plan.create_rdv_and_notify(@rdv_plan.user, participation_attributes: @rdv_plan.motif.default_notifications_settings_for_participations)

    if rdv.valid?
      flash[:success] = t("users.rdvs.create.rdv_confirmed")

      rdv = @rdv_plan.rdv
      redirect_to users_rdv_path(@rdv_plan.rdv, invitation_token: rdv.participations.find_by(user_id: @rdv_plan.user_id).restricted_auth_token)
    else

      flash[:error] = rdv.errors.full_messages
      redirect_to rdv_plan_invitations_path(@rdv_plan.invitation_token)
    end
  end
end
