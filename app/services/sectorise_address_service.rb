class SectoriseAddressService < BaseService
  include SectorisationUtils

  def initialize(departement, city_code)
    @departement = departement
    @city_code = city_code
  end

  def perform
    infos = { organisations: organisations, enabled?: enabled? }
    infos.merge!({ zones: zones, sectors: sectors }) if enabled?
    OpenStruct.new(infos)
  end

  private

  def enabled?
    sectorisation_enabled?(@departement)
  end

  def organisations
    @organisations ||= begin
      if enabled?
        sectors
          .includes(attributions: [:organisation])
          .map(&:attributions)
          .to_a
          .flatten
          .map(&:organisation)
      else
        Organisation.where(departement: @departement)
      end
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
