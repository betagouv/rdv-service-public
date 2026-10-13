# Corrige manuellement les organisations.website invalides
#
# Usage:
#   rails runner scripts/correct_organisation_websites.rb

require "readline"

WHODUNNIT = "[Script] correct_organisation_websites".freeze

Organisation.where.not(website: [nil, ""]).find_each do |organisation|
  next if organisation.website_url.present?

  puts "Organisation ##{organisation.id} — #{organisation.name}"
  puts "  Site web actuel : #{organisation.website.inspect}"
  print "  (S)upprimer / (M)odifier / (P)asser : "

  case $stdin.gets.to_s.strip.downcase
  when "s"
    organisation.website = nil
    PaperTrail.request(whodunnit: WHODUNNIT) { organisation.save(validate: false) }
    puts "  Site web supprimé."
  when "m"
    Readline.pre_input_hook = lambda do
      Readline.insert_text(organisation.website)
      Readline.redisplay
      Readline.pre_input_hook = nil # le hook s'auto-supprime après la première exécution, à chaque attente d'input
    end
    input = Readline.readline("  Nouvelle URL : ", true).to_s.strip
    next if input.empty?

    if Organisation.valid_website_url?(input)
      organisation.website = input
      PaperTrail.request(whodunnit: WHODUNNIT) { organisation.save(validate: false) }
      puts "  Site web mis à jour, enregistré."
    else
      puts "  Passé, aucune écriture."
    end
  end
end
