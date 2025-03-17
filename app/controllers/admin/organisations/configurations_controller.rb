class Admin::Organisations::ConfigurationsController < AgentAuthController
  before_action :set_organisation

  def show
    authorize(@organisation, :edit?, policy_class: Agent::OrganisationPolicy)

    @agents_scope = current_organisation.agents.active

    @motif_names = current_organisation.motifs.active.pluck(:name).uniq
  end
end
