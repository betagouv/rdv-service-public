class Agents::AbsencesController < AgentAuthController
  respond_to :html, :json

  before_action :set_absence, only: [:edit, :update, :destroy]

  def index
    @agent = policy_scope(Agent).find(params[:agent_id])
    absences = policy_scope(Absence).where(agent_id: filter_params[:agent_id])
    respond_to do |f|
      f.json { @absence_occurrences = absences.flat_map { |ab| ab.occurences_for(date_range_params).map { |occurence| [ab, occurence] } }.sort_by(&:second) }
      f.html { @absences = absences.includes(:organisation).page(filter_params[:page]) }
    end
  end

  def new
    @agent = policy_scope(Agent).find(params[:agent_id])
    @absence = Absence.new(organisation: current_organisation, agent: @agent)
    authorize(@absence)
    respond_right_bar_with @absence
  end

  def edit
    authorize(@absence)
    respond_right_bar_with @absence
  end

  def create
    @absence = Absence.new(absence_params)
    @absence.organisation = current_organisation
    authorize(@absence)
    flash[:notice] = "L'absence a été créée." if @absence.save
    respond_right_bar_with @absence, location: organisation_agent_absences_path(@absence.organisation_id, @absence.agent_id)
  end

  def update
    authorize(@absence)
    flash[:notice] = "L'absence a été modifiée." if @absence.update(absence_params)
    respond_right_bar_with @absence, location: organisation_agent_absences_path(@absence.organisation_id, @absence.agent_id)
  end

  def destroy
    authorize(@absence)
    flash[:notice] = "L'absence a été supprimée." if @absence.destroy
    redirect_to organisation_agent_absences_path(@absence.organisation_id, @absence.agent_id)
  end

  private

  def set_absence
    @absence = policy_scope(Absence).find(params[:id])
  end

  def absence_params
    params.require(:absence).permit(:title, :agent_id, :first_day, :end_day, :start_time, :end_time, :recurrence)
  end

  def date_range_params
    start_param = Date.parse(filter_params[:start])
    end_param = Date.parse(filter_params[:end])
    start_param..end_param
  end

  def filter_params
    params.permit(:start, :end, :organisation_id, :agent_id, :page)
  end
end
