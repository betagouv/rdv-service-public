# frozen_string_literal: true

class Admin::TerritoriesController < Admin::Territories::BaseController
  skip_before_action :set_territory

  def show
    @territory = Territory.find(params[:id])
  end

  def update
    @territory = Territory.find(params[:id])
    authorize_admin(@territory)
    flash[:success] = "Mise à jour réussie !" if @territory.update(territory_params)
    render "admin/territories/agent_territorial_roles/index"
  end

  private

  def territory_params
    params.require(:territory).permit(:name, :phone_number)
  end
end
