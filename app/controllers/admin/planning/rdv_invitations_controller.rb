class Admin::Planning::RdvInvitationsController < AgentAuthController
  include Admin::Planning::PlanningConcern
  layout "application_agent"
  before_action :set_agents

  def index
    @rdv_invitations = policy_scope(RdvInvitation, policy_scope_class: Agent::RdvInvitationPolicy::Scope)
      .page(page_number)
  end

  def pundit_user
    current_agent
  end
end
