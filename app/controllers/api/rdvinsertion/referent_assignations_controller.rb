class Api::Rdvinsertion::ReferentAssignationsController < Api::V1::AgentAuthBaseController
  before_action :set_user, :set_agents, only: %i[create_many]

  def create_many
    @agents.each { |agent| ReferentAssignation.find_or_create_by!(user: @user, agent: agent) }
    head :ok
  end

  private

  def set_agents
    @agents = Agent.where(id: referent_assignations_params[:agent_ids])
      .joins(:organisations).where(organisations: { verticale: "rdv_insertion" }).distinct
  end

  def set_user
    @user = User.find(referent_assignations_params[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_error :not_found, not_found: :user
  end

  def referent_assignations_params
    params.permit(:user_id, agent_ids: [])
  end
end
