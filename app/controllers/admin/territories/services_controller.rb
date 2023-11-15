class Admin::Territories::ServicesController < Admin::Territories::BaseController
  def edit
    authorize current_territory
  end

  def update
    authorize current_territory
    current_territory.update(services_params)
    flash[:alert] = "Configuration enregistrée"
    redirect_to edit_admin_territory_services_path(current_territory)
  end

  private

  def services_params
    params.require(:territory).permit(service_ids: [])
  end
end
