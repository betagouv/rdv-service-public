class Agents::Departements::ZonesController < AgentDepartementAuthController
  def index
    @search_form = ZoneSearchForm.new(search_params)
    @zones = policy_scope(Zone)
      .includes(:organisation)
      .where(organisations: { departement: current_departement.number })
      .order(:organisation_id)
    @zones = @search_form.filter_zones(@zones)
    @zones = @zones.page(params[:page]) unless view_params[:view] == "map"
    authorize(@zones)
    return render :map if view_params[:view] == "map"
  end

  def new
    @zone = Zone.new(organisation: current_organisation)
    authorize(@zone)
  end

  def create
    @zone = Zone.new(**zone_params)
    authorize(@zone)
    if @zone.save
      redirect_to departement_zones_path(current_departement), flash: { success: "Zone créée" }
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
    params.require(:zone).permit(:organisation_id, :level, :city_name, :city_code)
  end

  def search_params
    params.permit(:level, :city, :orga_id)
  end

  def view_params
    params.permit(:view)
  end
end
