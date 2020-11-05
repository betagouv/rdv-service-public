module SectorsHelper
  def sector_zone_color(sector)
    "##{Digest::MD5.hexdigest("sector-#{sector.id}")[0..5]}"
  end

  def departement_sectorisation_enabled?(departement)
    Users::GeoSearch.new(departement: departement).departement_sectorisation_enabled?
  end
end
