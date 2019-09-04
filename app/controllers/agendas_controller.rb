class AgendasController < DashboardAuthController
  before_action :redirect_if_pro_incomplete, only: :index

  def index
    skip_policy_scope
    @organisation = current_pro.organisation
  end

  def events
    skip_authorization

    rdvs = current_pro.rdvs.active.where(start_at: date_range_params).includes(:motif)
    @events = rdvs.map do |rdv|
      {
        title: rdv.name,
        extendedProps: { status: rdv.status, past: rdv.past? },
        start: rdv.start_at,
        end: rdv.end_at,
        url: rdv_path(rdv),
        backgroundColor: rdv.motif&.color,
      }
    end

    @events = @events.sort_by { |e| e[:start] }

    render json: @events
  end

  def background_events
    skip_authorization

    @events = current_pro.plage_ouvertures.flat_map do |po|
      po.occurences_for(date_range_params).map do |occurence|
        {
          title: po.title,
          start: occurence,
          end: po.end_time.on(occurence),
          backgroundColor: "#F00",
          rendering: "background",
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

  def redirect_if_pro_incomplete
    return unless pro_signed_in?

    redirect_to(new_pros_full_subscription_path) && return unless current_pro.complete?
    redirect_to(new_organisation_path) && return if current_pro.organisation.nil?
  end
end
