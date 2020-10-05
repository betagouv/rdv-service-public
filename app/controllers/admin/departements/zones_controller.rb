class Admin::Departements::ZonesController < AgentDepartementAuthController
  before_action :set_sector

  def new
    @zone = Zone.new(sector: @sector)
    authorize(@zone)
  end

  def create
    @zone = Zone.new(**zone_params, sector: @sector)
    authorize(@zone)
    if @zone.save
      redirect_to admin_departement_sector_path(current_departement, @sector), flash: { success: "Zone créée" }
    else
      render :new
    end
  end

  def edit
    @zone = Zone.find(params[:id])
    authorize(@zone)
  end

  def update
    @zone = Zone.find(params[:id])
    @zone.assign_attributes(**zone_params)
    authorize(@zone)
    if @zone.save
      redirect_to admin_departement_sector_path(current_departement, @sector), flash: { success: "Zone mise à jour" }
    else
      render :edit
    end
  end

  def destroy
    zone = Zone.find(params[:id])
    authorize(zone)
    if zone.destroy
      redirect_to admin_departement_sector_path(current_departement, @sector), flash: { success: "Zone supprimée" }
    else
      redirect_to admin_departement_sector_path(current_departement, @sector), flash: { error: "Erreur lors de la suppression" }
    end
  end

  def destroy_multiple
    zones = @sector.zones
    zones = zones.filter { authorize(_1, :destroy?) }
    count = zones.count
    if zones.map(&:destroy).all?
      flash[:success] = "Les #{count} zones ont été supprimées"
    else
      flash[:danger] = "Erreur lors de la suppression des #{count} zones"
    end
    redirect_to admin_departement_sector_path(current_departement, @sector)
  end

  private

  def set_sector
    @sector = policy_scope(Sector).find(params[:sector_id])
  end

  def zone_params
    params.require(:zone).permit(:level, :city_name, :city_code)
  end
end
