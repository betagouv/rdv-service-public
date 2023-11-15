class Admin::Territories::ServicesController < Admin::Territories::BaseController
  def edit
    authorize current_territory

    activated_services = sort_and_format(current_territory.services)
    other_services = sort_and_format(Service.where.not(id: current_territory.service_ids))

    @services = activated_services + other_services
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

  def sort_and_format(services)
    services.sort_by { |s| I18n.transliterate(s.name).downcase }.map do |service|
      label = service.name

      agents_count = service.agents.active.merge(current_territory.organisations_agents).count
      if agents_count > 0
        label += " (#{agents_count} #{'agent'.pluralize(agents_count)})"
      end

      [label, service.id]
    end
  end
end
