class Admin::Territories::BaseController < ApplicationController
  include Admin::AuthenticatedControllerConcern

  layout "application_agent_departement"

  before_action :set_territory

  def current_territory
    @territory
  end
  helper_method :current_territory

  def pundit_user
    AgentContext.new(current_agent)
  end

  private

  def set_territory
    @territory = Territory.find(params[:territory_id])
  end
end
