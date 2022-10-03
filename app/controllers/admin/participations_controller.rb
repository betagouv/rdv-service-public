class Admin::ParticipationsController < AgentAuthController
  # Participation is @rdv.rdvs_users
  include ParticipationsHelper

  before_action :set_rdvs_user

  def update
    # TODORDV-C auth on rdv or auth on rdvs_user?
    authorize(@rdv, :update?)
    if @rdvs_user.update(rdvs_user_params)
      flash[:notice] = "Status de participation pour #{@rdvs_user.user.full_name} mis à jour"
      # TODORDV-C Notifs
      redirect_to admin_organisation_rdv_path(current_organisation, @rdv)
    else
      flash[:error] = @rdv.errors.full_messages.to_sentence
      redirect_to admin_organisation_rdv_path(current_organisation, @rdv)
    end
  end

  def destroy
    # TODORDV-C auth on rdv or auth on rdvs_user?
    authorize(@rdv)
    if @rdvs_user.destroy
      flash[:notice] = "La participation de l'usager au rdv a été supprimée."
      redirect_to admin_organisation_rdv_path(current_organisation, @rdv)
    else
      flash[:error] = @rdv.errors.full_messages.to_sentence
      redirect_to admin_organisation_rdv_path(current_organisation, @rdv)
    end
  end

  private

  def set_rdvs_user
    @rdv = policy_scope(Rdv).find(params[:rdv_id])
    @rdvs_user = @rdv.rdvs_users.find(params[:id])
  end

  def rdvs_user_params
    params.require(:rdvs_user).permit(:status)
  end

end
