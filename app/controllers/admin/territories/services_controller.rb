class Admin::Territories::ServicesController < Admin::Territories::BaseController
  def update
    authorize current_territory
    current_territory.update(territory_services_params)
    flash[:alert] = "Configuration enregistrée"
    redirect_to edit_admin_territory_service_fields_path(current_territory)
  end

  private

  def territory_services_params
    params.require(:territory).permit(territory_service_ids: [])
  end
end
