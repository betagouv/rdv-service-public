module SectorsHelper
  def sector_zone_color(sector)
    "##{Digest::MD5.hexdigest("sector-#{sector.id}")[0..5]}"
  end
end
