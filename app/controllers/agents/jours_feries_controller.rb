class Agents::JoursFeriesController < AgentAuthController
  respond_to :json

  def index
    skip_policy_scope
    respond_to do |f|
      f.json do
        @jours_feries = JoursFeriesService.all_in_date_range(date_range_params)
      end
    end
  end

  private

  def date_range_params
    start_param = Date.parse(filter_params[:start])
    end_param = Date.parse(filter_params[:end])
    start_param..end_param
  end

  def filter_params
    params.permit(:start, :end)
  end
end
