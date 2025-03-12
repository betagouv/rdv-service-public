class Admin::Organisations::SettingsController < AgentAuthController
  before_action :set_organisation

  def show
    authorize(@organisation, policy_class: Agent::OrganisationPolicy)
  end
end
