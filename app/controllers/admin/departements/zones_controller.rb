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
      redirect_to admin_departement_sector_path(current_departement, @sector), flash: { success: "Commune ajoutée au secteur" }
    else
      render :new
    end
  end

  def destroy
    zone = Zone.find(params[:id])
    authorize(zone)
    if zone.destroy
      redirect_to admin_departement_sector_path(current_departement, @sector), flash: { success: "Commune retirée du secteur" }
    else
      redirect_to admin_departement_sector_path(current_departement, @sector), flash: { error: "Erreur lors du retrait de la commune" }
    end
  end

  def destroy_multiple
    zones = @sector.zones
    zones = zones.filter { authorize(_1, :destroy?) }
    count = zones.count
    if zones.map(&:destroy).all?
      flash[:success] = "Les #{count} communes ont été retirées du secteur"
    else
      flash[:danger] = "Erreur lors du retrait des #{count} communes"
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
