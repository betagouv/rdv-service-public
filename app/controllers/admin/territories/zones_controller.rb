# frozen_string_literal: true

class Admin::Territories::ZonesController < Admin::Territories::BaseController
  before_action :set_sector, except: [:index]

  def index
    zones = policy_scope(Zone)
      .where(params[:sector_id].present? ? { sector: params[:sector_id] } : {})
    respond_to do |format|
      format.xls do
        send_data(
          ExportZonesService.new(zones).perform,
          filename: "zones_territory_#{current_territory.departement_number}.xls",
          type: "application/xls"
        )
      end
    end
  end

  def new
    zone_defaults = { level: params[:default_zone_level] || Zone::LEVEL_CITY }
    @zone = Zone.new(**zone_defaults.merge(zone_params_get), sector: @sector)
    @sectors = policy_scope(Sector)
    authorize @zone
  end

  def create
    @zone = Zone.new(**zone_params, sector: @sector)
    authorize @zone
    if @zone.save
      if params[:commit] == I18n.t("helpers.submit.create")
        redirect_to admin_territory_sector_path(current_territory, @sector), flash: { success: "#{@zone.human_attribute_value(:level)} ajoutée au secteur" }
      else
        redirect_to new_admin_territory_sector_zone_path(current_territory, @sector, default_zone_level: @zone.level), flash: { success: t(".created", zone: @zone.name) }
      end
    else
      render :new
    end
  end

  def destroy
    zone = Zone.find(params[:id])
    authorize zone
    if zone.destroy
      redirect_to admin_territory_sector_path(current_territory, @sector), flash: { success: "#{zone.human_attribute_value(:level)} retirée du secteur" }
    else
      redirect_to admin_territory_sector_path(current_territory, @sector), flash: { error: "Erreur lors du retrait de la #{zone.human_attribute_value(:level)}" }
    end
  end

  def destroy_multiple
    zones = @sector.zones
    zones = zones.filter { |z| authorize(z, :destroy?) }
    count = zones.count
    if zones.map(&:destroy).all?
      flash[:success] = "Les #{count} communes et rues ont été retirées du secteur"
    else
      flash[:danger] = "Erreur lors du retrait des #{count} communes et rues"
    end
    redirect_to admin_territory_sector_path(current_territory, @sector)
  end

  private

  def set_sector
    @sector = policy_scope(Sector).find(params[:sector_id])
  end

  def zone_params_get
    params.permit(:level)
  end

  def zone_params
    params.require(:zone).permit(:level, :city_name, :city_code, :street_ban_id, :street_name)
  end
end
