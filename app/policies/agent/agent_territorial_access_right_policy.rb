class Agent::AgentTerritorialAccessRightPolicy
  def initialize(agent, agent_territorial_access_right)
    @current_agent = agent
    @agent_territorial_access_right = agent_territorial_access_right
  end

  delegate :allow_to_manage_access_rights?, to: :territory_policy

  def edit?
    allow_to_manage_access_rights? || edit_territory_admin?
  end
  alias update? edit?

  def edit_territory_admin?
    territorial_admin? && agent_in_scope?
  end

  # cf. https://github.com/varvet/pundit#strong-parameters
  # Chaque champ n'est permis que si l'agent courant a le droit de le modifier ; les autres sont
  # silencieusement filtrés par `.permit` dans le contrôleur, pas besoin de vérifier après-coup.
  def permitted_attributes
    attributes = []
    attributes += %i[allow_to_manage_teams allow_to_manage_access_rights allow_to_invite_agents] if allow_to_manage_access_rights?
    attributes << :territory_admin if edit_territory_admin?
    attributes
  end

  private

  def territory_policy
    Agent::TerritoryPolicy.new(@current_agent, @agent_territorial_access_right.territory)
  end

  def territorial_admin?
    @current_agent.territorial_admin_in?(@agent_territorial_access_right.territory)
  end

  def agent_in_scope?
    Agent::AgentPolicy::Scope.new(@current_agent, Agent).resolve.exists?(id: @agent_territorial_access_right.agent_id)
  end
end
