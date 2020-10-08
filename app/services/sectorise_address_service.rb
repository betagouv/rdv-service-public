class SectoriseAddressService < BaseService
  include SectorisationUtils

  def initialize(departement, city_code)
    @departement = departement
    @city_code = city_code
  end

  def perform
    infos = {
      attributed_organisations: attributed_organisations,
      enabled?: enabled?
    }
    if enabled?
      infos.merge!(
        zones: zones,
        sectors: sectors,
        attributed_agents_by_organisation: attributed_agents_by_organisation
      )
    end
    OpenStruct.new(infos)
  end

  private

  def enabled?
    # ||= does not work with boolean values
    @enabled = @enabled.nil? ? sectorisation_enabled?(@departement) : @enabled
  end

  def attributed_organisations
    @attributed_organisations ||= \
      if enabled?
        SectorAttribution
          .includes(:organisation)
          .level_organisation
          .where(sector_id: sectors.pluck(:id))
          .map(&:organisation)
      else
        Organisation.where(departement: @departement)
      end
  end

  def attributed_agents_by_organisation
    @attributed_agents_by_organisation ||= begin
      by_orga = {}
      sectors.each do |sector|
        sector.attributions.level_agent.each do |attribution|
          by_orga[attribution.organisation] = [] unless by_orga.keys.include?(attribution.organisation)
          by_orga[attribution.organisation] << attribution.agent
        end
      end
      by_orga
    end
  end

  def zones
    return nil unless enabled?

    @zones ||= Zone.includes(:sector).where(city_code: @city_code)
  end

  def sectors
    return nil unless enabled?

    @sectors ||= Sector.where(id: zones.pluck(:sector_id))
  end
end
