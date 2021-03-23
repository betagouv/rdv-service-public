# rails runner scripts/export_sectors.rb 64

require "csv"
departement = ARGV[0]
exit unless departement.present?

zones = Sector
  .order(:name)
  .joins(:territory)
  .where(territories: { departement_number: departement })
  .flat_map do |sector|
  sector.zones.includes(:sector).cities.order(:city_name).to_a +
    sector.zones.includes(:sector).streets.order(:street_name).to_a
end

CSV.open("sector_zones_#{departement}.csv", "wb") do |csv|
  csv << %w[sector_name sector_id sector_id city_code city_name street_name street_code]
  zones.each do |zone|
    csv << [
      zone.sector.name,
      zone.sector.human_id,
      zone.city_code,
      zone.city_name,
      zone.street_name,
      zone.street_ban_id
    ]
  end
end
