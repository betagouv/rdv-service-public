class Api::V1::ParticipationsController < Api::V1::AgentAuthBaseController
  def update
    participation = policy_scope(Participation).find(params[:id])

    if participation_params[:status].present?
      participation.change_status_and_notify(current_agent, participation_params[:status])
    end

    render_record participation.rdv
  end

  private

  def participation_params
    params.require(:participation).permit(:status)
  end
end
