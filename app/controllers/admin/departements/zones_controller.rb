class Admin::Departements::ZonesController < AgentDepartementAuthController
  before_action :set_sector

  def new
    zone_defaults = { level: Zone::LEVEL_CITY }
    @zone = Zone.new(**zone_defaults.merge(zone_params_get), sector: @sector)
    authorize(@zone)
  end

  def create
    @zone = Zone.new(**zone_params, sector: @sector)
    authorize(@zone)
    if @zone.save
      redirect_to admin_departement_sector_path(current_departement, @sector), flash: { success: "#{Zone.human_enum_name(:level, @zone.level)} ajoutée au secteur" }
    else
      render :new
    end
  end

  def destroy
    zone = Zone.find(params[:id])
    authorize(zone)
    if zone.destroy
      redirect_to admin_departement_sector_path(current_departement, @sector), flash: { success: "#{Zone.human_enum_name(:level, zone.level)} retirée du secteur" }
    else
      redirect_to admin_departement_sector_path(current_departement, @sector), flash: { error: "Erreur lors du retrait de la #{Zone.human_enum_name(:level, zone.level)}" }
    end
  end

  def destroy_multiple
    zones = @sector.zones
    zones = zones.filter { authorize(_1, :destroy?) }
    count = zones.count
    if zones.map(&:destroy).all?
      flash[:success] = "Les #{count} communes et rues ont été retirées du secteur"
    else
      flash[:danger] = "Erreur lors du retrait des #{count} communes et rues"
    end
    redirect_to admin_departement_sector_path(current_departement, @sector)
  end

  private

  def set_sector
    @sector = policy_scope(Sector).find(params[:sector_id])
  end

  def zone_params_get
    params.permit(:level)
  end

  def zone_params
    params.require(:zone).permit(:level, :city_name, :city_code, :street_ban_id, :street_name)
  end
end
