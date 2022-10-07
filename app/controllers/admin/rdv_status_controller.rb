class Admin::RdvsStatusController < AgentAuthController
  def update
    authorized(@rdv)
    @rdv.change_status(current_agent, rdv_status_params)
    # update.js.erb
    # if @rdv.errors
    # flash
    # else
    # mettre à jour le template
  end

  private

  def rdv_status_params
    params.require(:rdv).permit(:status)
  end
end
