# frozen_string_literal: true

class Admin::ParticipationsController < AgentAuthController
  # Participation is @rdv.rdvs_users
  include ParticipationsHelper

  before_action :set_rdvs_user

  def update
    authorize(@rdv, :update?)
    @success = @rdvs_user.change_status(current_agent, rdvs_user_params[:status])
    respond_to do |format|
      format.js do
        if @success
          flash.now[:notice] = "Status de participation pour #{@rdvs_user.user.full_name} mis à jour"
        else
          flash.now[:error] = @rdvs_user.errors.full_messages.to_sentence
        end
        render "admin/rdvs_users/update"
      end
    end
  end

  def destroy
    authorize(@rdv)
    if @rdvs_user.destroy
      flash[:notice] = "La participation de l'usager au rdv a été supprimée."
    else
      flash[:error] = @rdvs_user.errors.full_messages.to_sentence
    end
    redirect_to admin_organisation_rdv_path(current_organisation, @rdv)
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
