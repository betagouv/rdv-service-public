# frozen_string_literal: true

class Admin::RdvsStatusesController < AgentAuthController
  before_action :set_rdv

  def update
    authorize(@rdv, :update?)
    @success = @rdv.change_status(current_agent, rdv_status_params[:status])
    respond_to do |format|
      format.js do
        if @success
          flash.now[:notice] = "Status du rendez vous mis à jour"
        else
          flash.now[:error] = @rdv.errors.full_messages.to_sentence
        end
        render "admin/rdvs/update"
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
