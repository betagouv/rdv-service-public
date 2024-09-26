# Ce script permet de copier les utilisateurs d'une ou plusieurs organisations source vers une organisation cible.
# utilisation : rails runner scripts/copy_users_between_orgas.rb -s 148,147,146,145,144 -t 149

require "optparse"

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: rails runner scripts/copy_users_between_orgas.rb [options]"

  opts.on("-sORG_IDS", "--source=ORG_IDS", "Source organisation IDs (séparés par des virgules ou répétez -s)") do |v|
    options[:source_organisation_ids] ||= []
    options[:source_organisation_ids] += v.split(",").map(&:to_i)
  end

  opts.on("-tORG_ID", "--target=ORG_ID", Integer, "Target organisation ID") do |v|
    options[:target_organisation_id] = v
  end

  opts.on("-h", "--help", "Affiche cette aide") do
    puts opts
    exit
  end
end.parse!

if options[:source_organisation_ids].blank?
  puts "Erreur : Les IDs des organisations sources sont requis."
  puts "Utilisez -h pour afficher l'aide."
  exit 1
end

if options[:target_organisation_id].nil?
  puts "Erreur : L'ID de l'organisation cible est requis."
  puts "Utilisez -h pour afficher l'aide."
  exit 1
end

CopyUsersBetweenOrganisationsService.new(
  options[:source_organisation_ids],
  options[:target_organisation_id]
).perform
