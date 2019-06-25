class PlageOuverturesController < DashboardAuthController
  before_action :set_plage_ouverture, only: [:edit, :update, :destroy]

  def index
    @plage_ouvertures = policy_scope(PlageOuverture).all
  end

  def new
    @plage_ouverture = PlageOuverture.new(organisation: current_pro.organisation, pro: current_pro)
    authorize(@plage_ouverture)
  end

  def edit
    authorize(@plage_ouverture)
  end

  def create
    @plage_ouverture = PlageOuverture.new(plage_ouverture_params)
    @plage_ouverture.organisation = current_pro.organisation
    @plage_ouverture.pro = current_pro

    authorize(@plage_ouverture)
    if @plage_ouverture.save
      flash[:notice] = "Plage d'ouverture créé."
      redirect_to organisation_plage_ouvertures_path(current_pro.organisation)
    else
      render :new
    end
  end

  def update
    authorize(@plage_ouverture)
    if @plage_ouverture.update(plage_ouverture_params)
      flash[:notice] = "La plage d'ouverture a été modifiée."
      redirect_to organisation_plage_ouvertures_path(current_pro.organisation)
    else
      render :edit
    end
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
    params.require(:plage_ouverture).permit(:title, :first_day, :start_time, :end_time, motif_ids: [])
  end
end
