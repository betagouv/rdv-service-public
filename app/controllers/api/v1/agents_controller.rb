class Api::V1::AgentsController < Api::V1::AgentAuthBaseController
  def index
    agents = policy_scope(Agent).distinct
    agents = agents.joins(:organisations).where(organisations: { id: current_organisation.id }) if current_organisation.present?
    render_collection(agents.order(:created_at))
  end

  def sign_in_as
    super_admin = SuperAdmin.find_by(email: current_agent.email)
    authorize super_admin, :sign_in_as?

    # We use the AgentWithTokenAuth model rather than Agent to be able to use the create_new_auth_token method
    agent = AgentWithTokenAuth.find(params[:id])
    tokens = agent.create_new_auth_token

    # Update the response headers with the new tokens
    response.headers["client"] = tokens["client"]
    response.headers["uid"] = tokens["uid"]
    response.headers["access-token"] = tokens["access-token"]

    render json: { success: true }, status: :ok
  end
end
