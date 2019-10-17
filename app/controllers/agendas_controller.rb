class AgendasController < DashboardAuthController
  before_action :redirect_if_agent_incomplete, only: :index

  def index
    skip_policy_scope
    @organisation = current_agent.organisation
  end

  def background_events
    skip_authorization

    @events = current_agent.plage_ouvertures.flat_map do |po|
      po.occurences_for(date_range_params).map do |occurence|
        {
          title: po.title,
          start: occurence,
          end: po.end_time.on(occurence),
          backgroundColor: "#F00",
          rendering: "background",
          extendedProps: {
            location: po.lieu.address,
          },
        }
      end
    end

    @events = @events.sort_by { |e| e[:start] }

    render json: @events
  end

  private

  def date_range_params
    start_param..end_param
  end

  def start_param
    Date.parse(filter_params[:start])
  end

  def end_param
    Date.parse(filter_params[:end])
  end

  def filter_params
    params.permit(:start, :end)
  end

  def redirect_if_agent_incomplete
    return unless agent_signed_in?

    redirect_to(new_agents_full_subscription_path) && return unless current_agent.complete?
    redirect_to(new_organisation_path) && return if current_agent.organisation.nil?
  end
end
