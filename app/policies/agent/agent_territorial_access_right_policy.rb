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

  # À appeler une fois les nouveaux attributs assignés (pas encore sauvegardés) : vérifie que
  # chaque champ effectivement modifié reste dans le périmètre de l'agent courant. `edit?`/`update?`
  # ci-dessus ne fait qu'un contrôle grossier ("a-t-il un droit quelconque ici"), c'est cette méthode
  # qui empêche par exemple un agent avec seulement `allow_to_manage_teams` de s'octroyer `territory_admin`.
  def authorized_changes?
    return false if @agent_territorial_access_right.territory_admin_changed? && !territorial_admin?
    return false if specific_rights_changed? && !allow_to_manage_access_rights?

    true
  end

  def edit_territory_admin?
    territorial_admin? && agent_in_scope?
  end

  private

  def specific_rights_changed?
    @agent_territorial_access_right.changes.keys.map(&:to_sym).intersect?(%i[allow_to_manage_teams allow_to_manage_access_rights allow_to_invite_agents])
  end

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
