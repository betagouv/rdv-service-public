class Admin::Territories::AgentTeamMembershipsController < Admin::Territories::BaseController
  def update
    @agent = Agent.active.find(params[:agent_id])
    team_ids = params[:agent][:team_ids].map(&:presence).compact

    memberships_to_create = Team
      .where(id: team_ids)
      .where.not(id: @agent.agent_teams.pluck(:team_id))
      .map { AgentTeam.new(agent: @agent, team: _1) }

    memberships_to_destroy = AgentTeam
      .joins(:team)
      .where(teams: { territory_id: current_territory.id })
      .where(agent: @agent)
      .where.not(team_id: team_ids)
      .to_a

    (memberships_to_create + memberships_to_destroy)
      .each { authorize_agent(_1.team, :update?) }

    skip_authorization if memberships_to_create.empty? && memberships_to_destroy.empty?

    AgentTeam.transaction do
      memberships_to_create.each(&:save!)
      memberships_to_destroy.each(&:destroy!)
    end

    flash[:success] = "L'agent a été mis à jour"
    redirect_to edit_admin_territory_agent_path(current_territory, @agent.id)
  end

  def pundit_user
    current_agent
  end
end
