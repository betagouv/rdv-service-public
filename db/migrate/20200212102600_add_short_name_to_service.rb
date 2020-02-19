class AddShortNameToService < ActiveRecord::Migration[6.0]
  def up
    add_column :services, :short_name, :string
    Service.all.each do |s|
      s.update(short_name: s.name
                              .gsub('PMI (Protection Maternelle Infantile)', 'PMI')
                              .gsub("CPEF (Centre de planification et d'éducation familiale)", 'CPEF'))
    end
  end

  def down
    remove_column :services, :short_name
  end
end
