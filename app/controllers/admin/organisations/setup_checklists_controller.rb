class Admin::Organisations::SetupChecklistsController < AgentAuthController
  before_action :set_organisation

  def show
    authorize(@organisation)
    @lieux = policy_scope(Lieu)
    @other_agents = policy_scope(Agent).order_by_last_name.filter { |a| a.id != current_agent.id }

    @motifs = policy_scope(Motif)
  end
end
