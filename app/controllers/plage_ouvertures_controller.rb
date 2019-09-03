class PlageOuverturesController < DashboardAuthController
  respond_to :html, :json

  before_action :set_plage_ouverture, only: [:edit, :update, :destroy]

  def index
    @plage_ouvertures = policy_scope(PlageOuverture).all
  end

  def new
    @plage_ouverture = PlageOuverture.new(organisation: current_pro.organisation, pro: current_pro, first_day: Time.zone.now, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(12))
    authorize(@plage_ouverture)
    respond_right_bar_with @plage_ouverture
  end

  def edit
    authorize(@plage_ouverture)
    respond_right_bar_with @plage_ouverture
  end

  def create
    @plage_ouverture = PlageOuverture.new(plage_ouverture_params)
    @plage_ouverture.organisation = current_pro.organisation
    @plage_ouverture.pro = current_pro
    authorize(@plage_ouverture)
    flash[:notice] = "Plage d'ouverture créé." if @plage_ouverture.save
    respond_right_bar_with @plage_ouverture, location: organisation_plage_ouvertures_path(current_pro.organisation)
  end

  def update
    authorize(@plage_ouverture)
    flash[:notice] = "La plage d'ouverture a été modifiée." if @plage_ouverture.update(plage_ouverture_params)
    respond_right_bar_with @plage_ouverture, location: organisation_plage_ouvertures_path(current_pro.organisation)
  end

  def destroy
    authorize(@plage_ouverture)
    @plage_ouverture.destroy
    redirect_to organisation_plage_ouvertures_path(@plage_ouverture.organisation), notice: "La plage d'ouverture a été supprimée."
  end

  private

  def set_plage_ouverture
    @plage_ouverture = PlageOuverture.find(params[:id])
  end

  def plage_ouverture_params
    params.require(:plage_ouverture).permit(:title, :first_day, :start_time, :end_time, :location, :recurrence, motif_ids: [])
  end
end
