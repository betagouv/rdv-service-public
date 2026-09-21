class Api::Rdvinsertion::ReferentAssignationsController < Api::Rdvinsertion::AgentAuthBaseController
  before_action :set_user, only: %i[create_many index]
  before_action :set_agents, only: %i[create_many]

  def index
    referent_assignations = ReferentAssignation
      .where(user: @user)
      .joins(agent: :organisations)
      .where(organisations: { verticale: "rdv_insertion" })
      .distinct

    render_collection referent_assignations
  end

  def create_many
    @agents.each { |agent| ReferentAssignation.find_or_create_by!(user: @user, agent: agent) }
    head :ok
  end

  private

  # L'agent doit partager une organisation avec l'usager pour lui assigner des référents
  def set_user
    @user = User.find(referent_assignations_params[:user_id])
    authorize(@user, :show?, policy_class: Agent::UserPolicy)
  rescue ActiveRecord::RecordNotFound
    render_error :not_found, not_found: :user
  end

  # Les agents assignables ne sont volontairement pas restreints à ceux des organisations de l'agent : quand
  # rdv-insertion recrée un usager supprimé pour raison RGPD, il lui réassigne tous ses référents, y compris ceux
  # d'autres départements.
  def set_agents
    @agents = Agent.where(id: referent_assignations_params[:agent_ids])
      .joins(:organisations).where(organisations: { verticale: "rdv_insertion" }).distinct
  end

  def referent_assignations_params
    params.permit(:user_id, agent_ids: [])
  end
end
