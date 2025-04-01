# Usage:
# - mettre le fichier territories.csv dans tmp pour les territoires de rdv solidarites
# - exécuter: scalingo --app=production-rdv-solidarites --region=osc-secnum-fr1 run --file=tmp/territories.csv "scripts/territory_categories.rb"
#
# - mettre le fichier territories.csv dans tmp pour les territoires de rdv service public
# - exécuter: scalingo --app=production-rdv-mairie --region=osc-secnum-fr1 run --file=tmp/territories.csv "scripts/territory_categories.rb"

require "csv"

territories = CSV.read("/tmp/uploads/territories.csv", headers: true, col_sep: ",", liberal_parsing: true)
territories.each do |territory_line|
  territory = Territory.find(territory_line["ID"])
  territory.update!(category: territory_line["Catégorie"])
end
