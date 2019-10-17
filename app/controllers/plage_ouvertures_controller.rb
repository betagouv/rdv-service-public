class PlageOuverturesController < DashboardAuthController
  respond_to :html, :json

  before_action :set_plage_ouverture, only: [:edit, :update, :destroy]

  def index
    respond_to do |f|
      f.json do
        plage_ouvertures = policy_scope(current_agent.plage_ouvertures).flat_map do |po|
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
        end.sort_by { |e| e[:start] }

        render json: plage_ouvertures
      end
      f.html { @plage_ouvertures = policy_scope(PlageOuverture).includes(:lieu).all.page(params[:page]) }
    end
  end

  def new
    @plage_ouverture = PlageOuverture.new(organisation: current_agent.organisation, agent: current_agent, first_day: Time.zone.now, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(12))
    authorize(@plage_ouverture)
    respond_right_bar_with @plage_ouverture
  end

  def edit
    authorize(@plage_ouverture)
    respond_right_bar_with @plage_ouverture
  end

  def create
    @plage_ouverture = PlageOuverture.new(plage_ouverture_params)
    @plage_ouverture.organisation = current_agent.organisation
    @plage_ouverture.agent_id = current_agent.id
    authorize(@plage_ouverture)
    flash[:notice] = "Plage d'ouverture créé." if @plage_ouverture.save
    respond_right_bar_with @plage_ouverture, location: plage_ouvertures_path
  end

  def update
    authorize(@plage_ouverture)
    flash[:notice] = "La plage d'ouverture a été modifiée." if @plage_ouverture.update(plage_ouverture_params)
    respond_right_bar_with @plage_ouverture, location: plage_ouvertures_path
  end

  def destroy
    authorize(@plage_ouverture)
    @plage_ouverture.destroy
    redirect_to plage_ouvertures_path(@plage_ouverture.organisation), notice: "La plage d'ouverture a été supprimée."
  end

  private

  def set_plage_ouverture
    @plage_ouverture = PlageOuverture.find(params[:id])
  end

  def plage_ouverture_params
    params.require(:plage_ouverture).permit(:title, :first_day, :start_time, :end_time, :lieu_id, :recurrence, motif_ids: [])
  end

  def date_range_params
    start_param = Date.parse(filter_params[:start])
    end_param = Date.parse(filter_params[:end])
    start_param..end_param
  end

  def filter_params
    params.permit(:start, :end)
  end
end
