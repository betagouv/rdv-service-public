class Admin::Departements::SectorAttributionsController < AgentDepartementAuthController
  before_action :set_sector

  def create
    @sector_attribution = SectorAttribution.new(**sector_attribution_params, sector: @sector)
    authorize(@sector_attribution)
    if @sector_attribution.save
      redirect_to admin_departement_sector_path(current_departement, @sector), flash: { success: "Attribution créée" }
    else
      redirect_to admin_departement_sector_path(current_departement, @sector), flash: { error: "Erreur lors de la création de l'attribution: #{@sector_attribution.errors.full_messages.join(', ')}" }
    end
  end

  def destroy
    sector_attribution = SectorAttribution.find(params[:id])
    authorize(sector_attribution)
    if sector_attribution.destroy
      redirect_to admin_departement_sector_path(current_departement, @sector), flash: { success: "Attribution supprimée" }
    else
      redirect_to admin_departement_sector_path(current_departement, @sector), flash: { error: "Erreur lors de la suppression" }
    end
  end

  private

  def set_sector
    @sector = policy_scope(Sector).find(params[:sector_id])
  end

  def sector_attribution_params
    params.require(:sector_attribution).permit(:level, :organisation_id)
  end
end
