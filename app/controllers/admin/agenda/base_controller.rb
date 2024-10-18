class Admin::Agenda::BaseController < ApplicationController
  include Admin::AuthenticatedControllerConcern

  respond_to :json

  private

  def time_range_params
    start_time = params.require(:start)
    end_time = params.require(:end)
    Time.zone.parse(start_time)..Time.zone.parse(end_time)
  end

  def date_range_params
    (time_range_params.begin.to_date)..(time_range_params.end.to_date)
  end
  helper_method :date_range_params

  def pundit_user
    AgentContext.new(current_agent)
  end
end
