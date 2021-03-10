class Admin::AbsencesController < AgentAuthController
  respond_to :html, :json

  before_action :set_absence, only: [:show, :edit, :update, :destroy]
  before_action :build_absence, only: [:create]
  before_action :set_agent

  def index
    absences = policy_scope(Absence)
      .where(organisation: current_organisation)
      .where(agent_id: filter_params[:agent_id])
    respond_to do |f|
      f.json { @absence_occurrences = absences.flat_map { |ab| ab.occurences_for(date_range_params).map { |occurence| [ab, occurence] } }.sort_by(&:second) }
      f.html { @absences = absences.includes(:organisation).page(filter_params[:page]) }
    end
  end

  def new
    @absence = Absence.new(organisation: current_organisation, agent: @agent)
    authorize(@absence)
  end

  def edit
    authorize(@absence)
  end

  def create
    @absence.organisation = current_organisation
    authorize(@absence)
    if @absence.save
      flash[:notice] = "L'absence a été créée."
      redirect_to admin_organisation_agent_absences_path(@absence.organisation_id, @absence.agent_id)
    else
      render :edit
    end
  end

  def update
    authorize(@absence)
    if @absence.update(absence_params)
      flash[:notice] = "L'absence a été modifiée."
      redirect_to admin_organisation_agent_absences_path(@absence.organisation_id, @absence.agent_id)
    else
      render :edit
    end
  end

  def destroy
    authorize(@absence)
    if @absence.destroy
      flash[:notice] = "L'absence a été supprimée."
      redirect_to admin_organisation_agent_absences_path(@absence.organisation_id, @absence.agent_id)
    else
      render :edit
    end
  end

  private

  def set_absence
    @absence = policy_scope(Absence)
      .where(organisation: current_organisation)
      .find(params[:id])
  end

  def build_absence
    @absence = Absence.new(absence_params)
  end

  def set_agent
    @agent = filter_params[:agent_id].present? ? policy_scope(Agent).find(filter_params[:agent_id]) : @absence.agent
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
