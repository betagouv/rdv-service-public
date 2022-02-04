# frozen_string_literal: true

class Admin::Territories::BaseController < ApplicationController
  include Admin::AuthenticatedControllerConcern

  layout "application_configuration"

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
    @territory = if params[:territory_id]
                   Territory.find(params[:territory_id])
                 else
                   current_agent.territories.first
                 end
  end
end
