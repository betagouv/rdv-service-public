class AbsencesController < DashboardAuthController
  respond_to :html, :json

  before_action :set_absence, only: [:edit, :update, :destroy]

  def index
    absences = policy_scope(Absence)
    respond_to do |f|
      f.json { @absences = absences.in_time_range(date_range_params).order(:starts_at) }
      f.html { @absences = absences.includes(:organisation).page(params[:page]) }
    end
  end

  def new
    @absence = Absence.new(organisation: current_organisation, agent: current_agent)
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
    @absence.agent = current_agent
    authorize(@absence)
    flash[:notice] = "L'absence a été créée." if @absence.save
    respond_right_bar_with @absence, location: organisation_absences_path(@absence.organisation_id)
  end

  def update
    authorize(@absence)
    flash[:notice] = "L'absence a été modifiée." if @absence.update(absence_params)
    respond_right_bar_with @absence, location: organisation_absences_path(@absence.organisation_id)
  end

  def destroy
    authorize(@absence)

    flash[:notice] = "L'absence a été supprimée." if @absence.destroy
    redirect_to organisation_absences_path(@absence.organisation_id)
  end

  private

  def set_absence
    @absence = policy_scope(Absence).find(params[:id])
  end

  def absence_params
    params.require(:absence).permit(:title, :starts_at, :ends_at)
  end

  def date_range_params
    start_param = Date.parse(filter_params[:start])
    end_param = Date.parse(filter_params[:end])
    start_param..end_param
  end

  def filter_params
    params.permit(:start, :end, :organisation_id)
  end
end
