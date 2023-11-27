class Admin::RdvsCollectifs::MotifsController < AgentAuthController
  def index
    @motifs = Agent::MotifPolicy::Scope.apply(current_agent, Motif).available_motifs_for_organisation_and_agent(current_organisation, current_agent).collectif
  end
end
