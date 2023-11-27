class Admin::RdvsCollectifs::MotifsController < AgentAuthController
  def index
    @motifs = policy_scope(Motif).available_motifs_for_organisation_and_agent(current_organisation, current_agent).collectif
  end

  private

  def pundit_user
    current_agent
  end
end
