class Admin::Agenda::FullCalendarController < ApplicationController
  include Admin::AuthenticatedControllerConcern
  respond_to :json

  private

  def date_range_params
    start_param = Date.parse(params[:start])
    end_param = Date.parse(params[:end])
    start_param..end_param
  end
  helper_method :date_range_params

  def pundit_user
    AgentContext.new(current_agent)
  end
end
