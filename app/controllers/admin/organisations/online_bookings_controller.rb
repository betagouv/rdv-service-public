class Admin::Organisations::OnlineBookingsController < AgentAuthController
  before_action :set_organisation

  def show
    authorize(@organisation, policy_class: Agent::OrganisationPolicy)

    @motifs = Agent::MotifPolicy::Scope.apply(current_agent, Motif)
      .available_motifs_for_organisation_and_agent(current_organisation, current_agent)
      .active
      .includes(:organisation)
      .includes(:service)
  end
end
