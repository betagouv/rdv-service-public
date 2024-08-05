class Admin::Territories::SectorAttributionsController < Admin::Territories::BaseController
  before_action :set_sector

  def new
    @sector_attribution = SectorAttribution.new(**sector_attribution_params_get, sector: @sector)
    prepare_available_organisations_and_agents
    authorize_agent @sector_attribution
  end

  def create
    @sector_attribution = SectorAttribution.new(**sector_attribution_params, sector: @sector)
    authorize_agent @sector_attribution
    if @sector_attribution.save
      redirect_to admin_territory_sector_path(current_territory, @sector), flash: { success: "Attribution ajoutée" }
    else
      prepare_available_organisations_and_agents
      render :new
    end
  end

  def destroy
    sector_attribution = SectorAttribution.find(params[:id])
    authorize_agent sector_attribution
    if sector_attribution.destroy
      redirect_to admin_territory_sector_path(current_territory, @sector), flash: { success: "Attribution retirée" }
    else
      redirect_to admin_territory_sector_path(current_territory, @sector), flash: { error: "Erreur lors du retrait de l'attribution" }
    end
  end

  private

  def prepare_available_organisations_and_agents
    @available_organisations = Organisation
      .where(territory: current_territory)
      .where.not(id: excluded_organisation_ids)
      .ordered_by_name
    return if @sector_attribution.level_organisation? || @sector_attribution.organisation.blank?

    existing_agent_attributions = @sector
      .attributions
      .level_agent
      .where(organagent: @sector_attribution.organisation)
    @available_agents = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope)
      .merge(@sector_attribution.organisation.agents)
      .where.not(id: existing_agent_attributions.pluck(:agent_id))
      .includes(:services)
  end

  def excluded_organisation_ids
    if @sector_attribution.level_organisation?
      @sector.attributions
    elsif @sector_attribution.level_agent?
      @sector.attributions.level_organisation
    end&.pluck(:organisation_id)
  end

  def set_sector
    @sector = Agent::SectorPolicy::Scope.new(current_agent, current_territory.sectors).find(params[:sector_id])
  end

  def sector_attribution_params
    params.require(:sector_attribution).permit(:level, :organisation_id, :agent_id)
  end

  def sector_attribution_params_get
    params.permit(:level, :organisation_id, :agent_id)
  end
end
