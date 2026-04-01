class Agents::InstanceExportsController < ApplicationController
  include Admin::AuthenticatedControllerConcern

  layout "application_agent_config"

  before_action { redirect_to(root_path) unless current_domain == Domain::RDV_AIDE_NUMERIQUE }

  def index
    skip_policy_scope
    redirect_to admin_organisation_instance_exports_path(current_agent.organisations.first)
  end
end
