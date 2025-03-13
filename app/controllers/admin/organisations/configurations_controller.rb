class Admin::Organisations::ConfigurationsController < AgentAuthController
  before_action :set_organisation

  def show
    authorize(@organisation, :edit?, policy_class: Agent::OrganisationPolicy)
  end
end
