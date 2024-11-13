class Api::Internal::BaseController < ApplicationController
  rescue_from Pundit::NotAuthorizedError, with: :agent_not_authorized

  before_action :authenticate_agent!
  before_action :set_default_format

  private

  # On override la méthode de devise pour renvoyer une erreur JSON plutôt qu'une redirection
  def authenticate_agent!
    unless current_agent
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def agent_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    render json: { error: t("#{policy_name}.#{exception.query}", scope: "pundit", default: :default) }, status: :forbidden
  end

  def set_default_format
    request.format = :json
  end

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
