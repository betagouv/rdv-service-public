class ExtractSectors < ActiveRecord::Migration[6.0]
  def up
    create_table :sectors do |t|
      t.string :departement, null: false, index: true
      t.string :name, null: false
      t.string :human_id, null: false, index: true
      t.timestamps
    end

    create_table :sector_attributions do |t|
      t.belongs_to :sector, null: false
      t.belongs_to :organisation, null: false
      t.string :level, null: false
    end

    add_belongs_to :zones, :sector
    organisations_with_zones.each { migrate_organisation(_1) }
    change_column_null :zones, :sector_id, false
    remove_column :zones, :organisation_id
  end

  def down
    add_belongs_to :zones, :organisation
    Zone.all.each do |zone|
      zone.update!(organisation_id: zone.sector.attributions.first.organisation_id)
    end
    remove_column :zones, :sector_id
    drop_table :sectors
    drop_table :sector_attributions
  end

  private

  def organisations_with_zones
    Organisation.where(id: Zone.select(:organisation_id).distinct.select(:organisation_id))
  end

  def migrate_organisation(organisation)
    human_id = organisation.human_id.presence || organisation.name.parameterize
    sector = Sector.create!(
      departement: organisation.departement,
      name: "Secteur de #{organisation.name}",
      human_id: human_id
    )
    SectorAttribution.create!(
      sector: sector,
      organisation: organisation,
      level: SectorAttribution::LEVEL_ORGANISATION
    )
    Zone.where(organisation_id: organisation.id).update_all(sector_id: sector.id)
  end
end
