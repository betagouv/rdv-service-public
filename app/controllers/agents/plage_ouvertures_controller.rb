class Agents::PlageOuverturesController < AgentAuthController
  respond_to :html, :json

  before_action :set_plage_ouverture, only: [:edit, :update, :destroy]

  def index
    @agent = policy_scope(Agent).find(filter_params[:agent_id])
    plage_ouvertures = policy_scope(PlageOuverture)
      .includes(:lieu, :organisation)
      .where(agent_id: filter_params[:agent_id])
      .order(recurrence: :asc, updated_at: :desc)
    respond_to do |f|
      f.json { @plage_ouverture_occurences = plage_ouvertures.flat_map { |po| po.occurences_for(date_range_params).map { |occurence| [po, occurence] } }.sort_by(&:second) }
      f.html do
        @current_tab = filter_params[:current_tab]
        @plage_ouvertures = plage_ouvertures
          .where(expired_cached: filter_params[:current_tab] == 'expired')
          .page(filter_params[:page])
      end
    end
  end

  def new
    @agent = Agent.find(params[:agent_id])
    @plage_ouverture = PlageOuverture.new(organisation: current_organisation, agent: @agent, first_day: Time.zone.now, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(12))
    authorize(@plage_ouverture)
    respond_right_bar_with @plage_ouverture
  end

  def edit
    authorize(@plage_ouverture)
    respond_right_bar_with @plage_ouverture
  end

  def create
    @plage_ouverture = PlageOuverture.new(plage_ouverture_params)
    @plage_ouverture.organisation = current_organisation
    authorize(@plage_ouverture)
    flash[:notice] = "Plage d'ouverture créée" if @plage_ouverture.save
    respond_right_bar_with @plage_ouverture, location: organisation_agent_plage_ouvertures_path(@plage_ouverture.organisation, @plage_ouverture.agent)
  end

  def update
    authorize(@plage_ouverture)
    flash[:notice] = "La plage d'ouverture a été modifiée." if @plage_ouverture.update(plage_ouverture_params)
    respond_right_bar_with @plage_ouverture, location: organisation_agent_plage_ouvertures_path(@plage_ouverture.organisation, @plage_ouverture.agent)
  end

  def destroy
    authorize(@plage_ouverture)
    @plage_ouverture.destroy
    redirect_to organisation_agent_plage_ouvertures_path(@plage_ouverture.organisation, @plage_ouverture.agent), notice: "La plage d'ouverture a été supprimée."
  end

  private

  def set_plage_ouverture
    @plage_ouverture = PlageOuverture.find(params[:id])
  end

  def plage_ouverture_params
    params.require(:plage_ouverture).permit(:title, :agent_id, :first_day, :start_time, :end_time, :lieu_id, :recurrence, motif_ids: [])
  end

  def date_range_params
    start_param = Date.parse(filter_params[:start])
    end_param = Date.parse(filter_params[:end])
    start_param..end_param
  end

  def filter_params
    params.permit(:start, :end, :organisation_id, :agent_id, :page, :current_tab)
  end
end
