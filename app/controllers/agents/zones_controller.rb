class Agents::ZonesController < AgentDepartementAuthController
  def index
    @search_form = ZoneSearchForm.new(search_params)
    @zones = policy_scope(Zone)
      .joins(:organisation)
      .where(organisations: { departement: current_departement.number })
      .order(:organisation_id)
    @zones = @search_form.filter_zones(@zones)
    @zones = @zones.page(params[:page])
    authorize(@zones)
  end

  def new
    @zone_form = ZoneForm.new(Zone.new(organisation: current_organisation))
    authorize(@zone_form.zone)
  end

  def create
    @zone_form = ZoneForm.new(Zone.new, **zone_params)
    authorize(@zone_form.zone)
    if @zone_form.save
      redirect_to departement_zones_path(current_departement), flash: { success: "Zone créée" }
    else
      render :new
    end
  end

  def edit
    @zone_form = ZoneForm.new(Zone.find(params[:id]))
    authorize(@zone_form.zone)
  end

  def update
    @zone_form = ZoneForm.new(Zone.find(params[:id]), **zone_params)
    authorize(@zone_form.zone)
    if @zone_form.save
      redirect_to departement_zones_path(current_departement), flash: { success: "Zone mise à jour" }
    else
      render :edit
    end
  end

  def destroy
    zone = Zone.find(params[:id])
    authorize(zone)
    if zone.destroy
      redirect_to departement_zones_path(current_departement), flash: { success: "Zone supprimée" }
    else
      redirect_to departement_zones_path(current_departement), flash: { error: "Erreur lors de la suppression" }
    end
  end

  def destroy_multiple
    search_form = ZoneSearchForm.new(search_params)
    zones = policy_scope(Zone)
    zones = search_form.filter_zones(zones)
    zones = zones.filter { authorize(_1, :destroy?) }
    count = zones.count
    if zones.map(&:destroy).all?
      flash[:success] = "Les #{count} zones ont été supprimées"
    else
      flash[:danger] = "Erreur lors de la suppression des #{count} zones"
    end
    redirect_to departement_zones_path(current_departement, **search_params)
  end

  private

  def zone_params
    params.require(:zone).permit(:organisation_id, :level, :city_name, :city_code, :city_label)
  end

  def search_params
    params.permit(:level, :city, :organisation_id)
  end
end
