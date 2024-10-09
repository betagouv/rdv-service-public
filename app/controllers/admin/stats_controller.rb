class Admin::StatsController < AgentAuthController
  respond_to :html, :json

  def index
    @stats = Stat.new(rdvs: rdvs_for_current_agent)
  end

  def rdvs
    authorize(current_agent, policy_class: Agent::AgentPolicy)
    render json: Stat.new(rdvs: rdvs_for_current_agent).rdvs_group_by_week_fr.chart_json
  end

  private

  def rdvs_for_current_agent
    # Nous n'affichons que des données statistiques, nous pouvons
    # considérer tous les RDVs de l'agent peu importe s'il est toujours
    # dans l'orga ou pas.
    skip_policy_scope
    current_agent.rdvs
  end
end
