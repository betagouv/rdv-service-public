class Admin::PlageOuverturesController < AgentAuthController
  respond_to :html, :json

  before_action :set_plage_ouverture, only: [:show, :edit, :update, :destroy]

  def show
    authorize(@plage_ouverture)
    set_overlapping_details
  end

  def index
    @agent = policy_scope(Agent).find(filter_params[:agent_id])
    plage_ouvertures = policy_scope(PlageOuverture)
      .includes(:lieu, :organisation)
      .where(agent_id: filter_params[:agent_id])
      .order(updated_at: :desc)
    respond_to do |f|
      f.json { @plage_ouverture_occurences = plage_ouvertures.flat_map { |po| po.occurences_for(date_range_params).map { |occurence| [po, occurence] } }.sort_by(&:second) }
      f.html do
        @current_tab = filter_params[:current_tab]
        @plage_ouvertures = plage_ouvertures
          .where(expired_cached: filter_params[:current_tab] == "expired")
          .page(filter_params[:page])
        @display_tabs = plage_ouvertures.where(expired_cached: true).any? || params[:current_tab] == "expired"
      end
    end
  end

  def new
    @agent = Agent.find(params[:agent_id])
    if params[:duplicate_plage_ouverture_id].present?
      original_po = PlageOuverture.find(params[:duplicate_plage_ouverture_id])
      defaults = original_po.slice(:title, :lieu_id, :motif_ids, :first_day, :start_time, :end_time, :recurrence)
    else
      defaults = {
        first_day: Time.zone.now,
        start_time: Tod::TimeOfDay.new(9),
        end_time: Tod::TimeOfDay.new(12),
      }
    end
    @plage_ouverture = PlageOuverture.new(
      organisation: current_organisation,
      agent: @agent,
      **defaults
    )
    authorize(@plage_ouverture)
  end

  def edit
    authorize(@plage_ouverture)
  end

  def create
    @plage_ouverture = PlageOuverture.new(plage_ouverture_params)
    @plage_ouverture.organisation = current_organisation
    authorize(@plage_ouverture)
    if @plage_ouverture.save
      flash[:notice] = "Plage d'ouverture créée"
      redirect_to admin_organisation_plage_ouverture_path(@plage_ouverture.organisation, @plage_ouverture)
    else
      set_overlapping_details
      render :new
    end
  end

  def update
    authorize(@plage_ouverture)
    set_overlapping_details
    if @plage_ouverture.update(plage_ouverture_params)
      redirect_to admin_organisation_plage_ouverture_path(@plage_ouverture.organisation, @plage_ouverture), notice: "La plage d'ouverture a été modifiée."
    else
      render :edit
    end
  end

  def destroy
    authorize(@plage_ouverture)
    @plage_ouverture.destroy
    redirect_to admin_organisation_agent_plage_ouvertures_path(@plage_ouverture.organisation, @plage_ouverture.agent), notice: "La plage d'ouverture a été supprimée."
  end

  private

  def set_plage_ouverture
    @plage_ouverture = PlageOuverture.find(params[:id])
  end

  def plage_ouverture_params
    params.require(:plage_ouverture).permit(:title, :agent_id, :first_day, :start_time, :end_time, :lieu_id, :recurrence, :active_warnings_confirm_decision, motif_ids: [])
  end

  def date_range_params
    start_param = Date.parse(filter_params[:start])
    end_param = Date.parse(filter_params[:end])
    start_param..end_param
  end

  def filter_params
    params.permit(:start, :end, :organisation_id, :agent_id, :page, :current_tab)
  end

  def set_overlapping_details
    @overlapping_plages_ouvertures = Agent::PlageOuverturePolicy::DepartementScope
      .new(pundit_user, PlageOuverture)
      .resolve
      .merge(@plage_ouverture.overlapping_plages_ouvertures)
    @overlapping_plages_ouvertures_out_of_scope_count = \
      @plage_ouverture.overlapping_plages_ouvertures.count - @overlapping_plages_ouvertures.count
  end
end
