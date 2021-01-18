class DeleteCorruptZones < ActiveRecord::Migration[6.0]
  def up
    sector_ids = Sector.pluck(:id)
    Zone.where.not(sector_id: sector_ids).each(&:destroy!)
  end

  def down; end
end
