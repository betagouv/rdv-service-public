# frozen_string_literal: true

class Admin::Territories::BaseController < ApplicationController
  include Admin::AuthenticatedControllerConcern

  layout "application_configuration"

  before_action :set_territory
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  def current_territory
    @territory
  end
  helper_method :current_territory

  def pundit_user
    AgentTerritorialContext.new(current_agent, current_territory)
  end
  helper_method :pundit_user

  def authorize(record, *args)
    super([:configuration, record], *args)
  end

  private

  def set_territory
    @territory = Territory.find(params[:territory_id])
  end
end
