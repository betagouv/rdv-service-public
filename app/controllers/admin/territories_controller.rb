class Admin::TerritoriesController < Admin::Territories::BaseController
  skip_before_action :set_territory
  before_action :set_territory_with_id

  def show; end

  def edit; end

  def update
    if @territory.update(territory_params)
      flash[:success] = "Mise à jour réussie !"
    else
      flash[:error] = "Erreur durant la mise à jour"
    end
    redirect_to edit_admin_territory_path(current_territory)
  end

  private

  def territory_params
    params.require(:territory).permit(:name, :phone_number)
  end

  def set_territory_with_id
    @territory = Territory.find(params[:id])
    authorize_agent @territory
  end
end
