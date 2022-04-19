# frozen_string_literal: true

class Admin::TerritoriesController < Admin::Territories::BaseController
  skip_before_action :set_territory

  def show
    @territory = Territory.find(params[:id])
    authorize @territory
  end

  def update
    @territory = Territory.find(params[:id])
    authorize @territory
    if @territory.update(territory_params)
      flash[:success] = "Mise à jour réussie !"
    else
      flash[:error] = "Erreur durant la mise à jour"
    end
    redirect_to admin_territory_agent_territorial_roles_path(current_territory)
  end

  private

  def territory_params
    params.require(:territory).permit(:name, :phone_number)
  end
end
