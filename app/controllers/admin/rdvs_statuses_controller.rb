# frozen_string_literal: true

class Admin::RdvsStatusesController < AgentAuthController

  before_action :set_rdv

  def update
    authorize(@rdv, :update?)
    success = @rdv.change_status(current_agent, rdv_status_params[:status])
    respond_to do |format|
      format.js { render "admin/rdvs/update" }
      format.html do
        if success
          flash[:notice] = "Status de participation mis à jour"
        else
          flash[:error] = @rdv.errors.full_messages.to_sentence
        end
        redirect_to admin_organisation_rdv_path(current_organisation, @rdv, agent_id: params[:agent_id])
      end
    end
  end

  private

  def set_rdv
    @rdv = policy_scope(Rdv).find(params[:id])
  end

  def rdv_status_params
    params.require(:rdv).permit(:status)
  end
end
