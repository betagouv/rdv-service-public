require "optparse"

options = {}
OptionParser.new do |opts|
  opts.banner = "Utilisation : move_organisation_to_other_territory.rb [options]"

  opts.on("--origin_organisation_id ORGANISATION_ID", "ID de l'organisation à déplacer") do |v|
    options[:origin_organisation_id] = v
  end

  opts.on("--target_territory_id TERRITORY_ID", "ID du territoire cible") do |v|
    options[:target_territory_id] = v
  end
end.parse!(ARGV)

if options[:origin_organisation_id].nil? || options[:target_territory_id].nil?
  puts "Les paramètres origin_organisation_id et target_territory_id sont obligatoires."
  exit 1
end

origin_organisation = Organisation.find_by(id: options[:origin_organisation_id])
unless origin_organisation
  puts "Organisation avec l'ID #{options[:origin_organisation_id]} introuvable."
  exit 1
end

target_territory = Territory.find_by(id: options[:target_territory_id])
unless target_territory
  puts "Territoire avec l'ID #{options[:target_territory_id]} introuvable."
  exit 1
end

puts <<~INFO

  Ce script va déplacer une organisation vers un autre territoire. Voici comment les différentes données seront traitées :

  - annotations (remarques usagers) : elles seront fusionnées s’il en existe déjà dans le territoire cible
  - motif_categories : on ajoutera les catégories de motifs manquantes au territoire cible
  - territory_services : on ajoutera les services manquants au territoire cible
  - teams : les équipes sont déplacées ; si une équipe existe déjà avec le même nom, elle sera réutilisée
  - agent territorial access_rights & roles : les droits sont combinés additivement (on ajoute des droits, on n’en retire pas)
  - sectors : ⚠️ les secteurs existants seront supprimés, ils ne seront pas déplacés
  - organisation : déplacée vers le territoire cible

  Êtes-vous sûr(e) de vouloir continuer ? (oui/non)
INFO

response = $stdin.gets.strip.downcase
unless response == "oui"
  puts "Opération annulée."
  exit 0
end

MoveOrganisationToOtherTerritoryService.new(
  origin_organisation: origin_organisation,
  target_territory: target_territory
).call
