class Api::V1::RdvsUsersController < Api::V1::AgentAuthBaseController
  def update
    rdvs_user = policy_scope(RdvsUser).find(params[:id])

    if rdvs_user_params[:status].present?
      rdvs_user.change_status_and_notify(current_agent, rdvs_user_params[:status])
    end

    render_record rdvs_user.rdv
  end

  private

  def rdvs_user_params
    params.require(:rdvs_user).permit(:status)
  end
end
