class Admin::Territories::ServicesController < Admin::Territories::BaseController
  def edit
    authorize(current_territory, policy_class: Agent::TerritoryPolicy)

    activated_services = format_for_checkboxes(current_territory.services)
    other_services = format_for_checkboxes(Service.where.not(id: current_territory.service_ids))

    @services = activated_services + other_services
  end

  def update
    authorize(current_territory, policy_class: Agent::TerritoryPolicy)
    current_territory.update!(services_params)
    flash[:alert] = "Liste des services disponibles mise à jour"

    if params[:redirect_to_organisation_id].present?
      redirect_to new_admin_organisation_agent_path(params[:redirect_to_organisation_id])
    else
      redirect_to edit_admin_territory_services_path(current_territory)
    end
  end

  private

  def services_params
    params.require(:territory).permit(service_ids: [])
  end

  def format_for_checkboxes(services)
    services.map do |service|
      label = service.name

      agents_count = service.agents.active.merge(current_territory.organisations_agents).count
      if agents_count > 0
        label += " (#{agents_count} #{'agent'.pluralize(agents_count)})"
      end

      [label, service.id]
    end
  end
end
