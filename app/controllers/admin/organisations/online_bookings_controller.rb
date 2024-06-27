class Admin::Organisations::OnlineBookingsController < AgentAuthController
  before_action :set_organisation

  def show
    authorize(@organisation)

    @motifs = Agent::MotifPolicy::UseScope.apply(current_agent, Motif.all)
      .available_motifs_for_organisation_and_agent(current_organisation, current_agent)
      .active
      .includes(:organisation)
      .includes(:service)
  end
end
