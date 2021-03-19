class Admin::Territories::SectorsController < Admin::Territories::BaseController
  def index
    @sectors = policy_scope_admin(Sector)
      .where(territory: current_territory)
      .includes(:attributions)
      .order_by_name
    @sectors = @sectors.page(params[:page]) unless params[:view] == "map"
    render :index_map if params[:view] == "map"
  end

  def new
    @sector = Sector.new(territory: current_territory)
    authorize_admin(@sector)
  end

  def create
    @sector = Sector.new(**sector_params, territory: current_territory)
    authorize_admin(@sector)
    if @sector.save
      redirect_path = params[:commit] == "Créer" ? admin_territory_sector_path(current_territory, @sector) : new_admin_territory_sector_path(current_territory)
      redirect_to redirect_path, flash: { success: "Secteur #{@sector.name} créé" }
    else
      render :new
    end
  end

  def show
    @sector = Sector.find(params[:id])
    authorize_admin(@sector)
    @zones = @sector.zones.order(updated_at: :desc).page(params[:page])
  end

  def edit
    @sector = Sector.find(params[:id])
    authorize_admin(@sector)
  end

  def update
    @sector = Sector.find(params[:id])
    @sector.assign_attributes(**sector_params)
    authorize_admin(@sector)
    if @sector.save
      redirect_to admin_territory_sectors_path(current_territory), flash: { success: "Commune mise à jour" }
    else
      render :edit
    end
  end

  def destroy
    sector = Sector.find(params[:id])
    authorize_admin(sector)
    if sector.destroy
      redirect_to admin_territory_sectors_path(current_territory), flash: { success: "Secteur supprimé" }
    else
      redirect_to admin_territory_sectors_path(current_territory), flash: { error: "Erreur lors de la suppression" }
    end
  end

  private

  def sector_params
    params.require(:sector).permit(:territory_id, :name, :human_id)
  end
end
