class FixTralingZerosInCityCodeInZones < ActiveRecord::Migration[6.0]
  def up
    Zone.where("city_code LIKE '%\.0%'").each do |zone|
      zone.update!(city_code: zone.city_code.gsub(/\.0$/, ""))
    end
  end
end
