# frozen_string_literal: true

class SearchCreneauxForAgentsBase < BaseService
  def initialize(agent_creneaux_search_form)
    @form = agent_creneaux_search_form
  end

  def all_agents
    Agent.where(id: @form.agent_ids).or(Agent.where(id: Agent.joins(:teams).where(teams: @form.team_ids)))
  end
end
