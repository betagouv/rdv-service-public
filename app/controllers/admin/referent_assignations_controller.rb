class Admin::ReferentAssignationsController < AgentAuthController
  def index
    @user = policy_scope(User).find(index_params[:user_id])
    authorize(@user, :update?)
    @referents = policy_scope(@user.referent_agents).distinct.order(:last_name)
    @agents = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope).merge(current_organisation.agents)
    @agents = @agents.search_by_text(index_params[:search]) if index_params[:search].present?
    @agents = @agents.page(page_number)
  end

  def create
    find_agent_and_user_save_and_redirect_with(params) do |user, agent|
      user.referent_assignations.find_or_create_by!(agent: agent)
    end
  end

  def destroy
    find_agent_and_user_save_and_redirect_with(params) do |user, agent|
      user.referent_assignations.find_by(agent: agent)&.destroy
    end
  end

  def find_agent_and_user_save_and_redirect_with(params)
    user = policy_scope(User).find(params[:user_id])
    authorize(user, :update?)
    agent = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope).find(params[:agent_id]) if params[:agent_id]
    agent ||= policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope).find(params[:id])

    yield(user, agent)

    flash[:error] = user.errors.full_messages.join(", ") unless user.save
    redirect_to admin_organisation_user_referent_assignations_path(current_organisation, user)
  end

  private

  def index_params
    @index_params ||= params.permit(:user_id, :search)
  end
end
