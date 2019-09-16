class AbsencesController < DashboardAuthController
  respond_to :html, :json

  before_action :set_absence, only: [:edit, :update, :destroy]

  def index
    @absences = policy_scope(Absence).all.page(params[:page])
    respond_right_bar_with @absences
  end

  def new
    @absence = Absence.new(organisation: current_pro.organisation, pro: current_pro)
    authorize(@absence)
    respond_right_bar_with @absence
  end

  def edit
    authorize(@absence)
    respond_right_bar_with @absence
  end

  def create
    @absence = Absence.new(absence_params)
    @absence.organisation = current_pro.organisation
    @absence.pro = current_pro
    authorize(@absence)
    flash[:notice] = "Absence créée." if @absence.save
    respond_right_bar_with @absence, location: absences_path
  end

  def update
    authorize(@absence)
    flash[:notice] = "L'absence a été modifiée." if @absence.update(absence_params)
    respond_right_bar_with @absence, location: absences_path
  end

  def destroy
    authorize(@absence)
    @absence.destroy
    redirect_to absences_path, notice: "L'absence a été supprimée."
  end

  private

  def set_absence
    @absence = Absence.find(params[:id])
  end

  def absence_params
    params.require(:absence).permit(:title, :starts_at, :ends_at)
  end
end
