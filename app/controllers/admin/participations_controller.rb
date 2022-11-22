# frozen_string_literal: true

class Admin::ParticipationsController < AgentAuthController
  # Participation is @rdv.rdvs_users
  include ParticipationsHelper
  respond_to :js

  before_action :set_rdv
  before_action :set_rdvs_user

  def update
    authorize(@rdv, :update?)
    if @rdvs_user.change_status_and_notify(current_agent, rdvs_user_params[:status])
      flash.now[:notice] = "Status de participation pour #{@rdvs_user.user.full_name} mis à jour"
    else
      flash.now[:error] = @rdvs_user.errors.full_messages.to_sentence
    end
    render "admin/rdvs/update"
  end

  def destroy
    authorize(@rdv)
    if @rdv.rdvs_users.destroy(@rdvs_user)
      flash[:notice] = "La participation de l'usager au rdv a été supprimée."
    else
      flash[:error] = @rdvs_user.errors.full_messages.to_sentence
    end
    redirect_to admin_organisation_rdv_path(current_organisation, @rdv)
  end

  private

  def set_rdv
    @rdv = policy_scope(Rdv).find(params[:rdv_id])
  end

  def set_rdvs_user
    @rdvs_user = @rdv.rdvs_users.find(params[:id])
  end

  def rdvs_user_params
    params.require(:rdvs_user).permit(:status)
  end
end
