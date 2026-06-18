class Admin::Territories::ServicesController < Admin::Territories::BaseController
  def new
    authorize(current_territory, :manage_services?, policy_class: Agent::TerritoryPolicy)
    permitted_params = params.permit(:name, :short_name)
    @service = Service.new(permitted_params)
  end

  def create
    authorize(current_territory, :manage_services?, policy_class: Agent::TerritoryPolicy)
    permitted_params = params.require(:service).permit(:name, :short_name)
    @service = Service.new(permitted_params)

    if @service.save
      current_territory.territory_services.find_or_create_by!(service_id: @service.id)
      flash[:success] = %(Le service "#{@service.name} (#{@service.short_name})" vient d'être créé et activé dans votre espace.)
      redirect_to edit_admin_territory_services_path(territory_id: current_territory.id)
    else
      render :new
    end
  end

  def edit
    authorize(current_territory, :manage_services?, policy_class: Agent::TerritoryPolicy)
    @filter = params[:filter].presence
    activated_service_ids = current_territory.services.ids.to_set
    displayed_services = @filter ? Service.filter_by_name(@filter) : Service.all

    # Display activated services first
    displayed_services = displayed_services.sort_by { |service| [service.id.in?(activated_service_ids) ? -1 : 1, service.name] }

    @displayed_services = displayed_services.reject(&:secretariat?)
  end

  def update
    authorize(current_territory, :manage_services?, policy_class: Agent::TerritoryPolicy)
    current_territory.update!(services_params)
    flash[:success] = "Liste des services disponibles mise à jour"

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

  helper_method :format_for_checkboxes
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
