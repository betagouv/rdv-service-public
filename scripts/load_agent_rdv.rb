# frozen_string_literal: true

#
# On ne gère pas les agents du RDV, on force avec le seul agent concerné.
#
# L'objectif pour l'instant, c'est de récupérér un conseiller numérique
# qui s'est installé sur la Démo au lieu de la prod...
#

EXCLUDE_KEYS = %w[id created_at updated_at old_address old_enabled enabled service_id organisation_id].freeze

SERVICE_ID = 3
ORGANISATION_ID = 4
AGENT_ID = 5
# 6971 en prod ?

if ARGV.blank?
  puts "il faut passer le chemin vers le fichier qui contient les rendez-vous au format json en paramètre du script"
  exit 0
end

rdvs = JSON.parse(File.read(ARGV[0]))

rdv_params = {}
users = []
agents = [Agent.find(AGENT_ID)]

rdvs.each do |rdv|
  rdv.each do |key, value|
    next if EXCLUDE_KEYS.include?(key)

    case key
    when "motif"
      puts "--- motif"
      motif = Motif.find_or_create_by!(value.reject { |k| EXCLUDE_KEYS.include?(k) }.merge(service_id: SERVICE_ID, organisation_id: ORGANISATION_ID))
      puts "motif trouvé ou créer (#{motif} ##{motif.id})"
      rdv_params[:motif_id] = motif.id
    when "lieu"
      puts "--- lieu"
      l = Lieu.find_or_create_by(value.reject { |k| EXCLUDE_KEYS.include?(k) }.merge(organisation_id: ORGANISATION_ID))
      puts "lieu trouvé ou créer (#{l.name})"
      rdv_params[:lieu] = l
    when "users"
      puts "--- users"
      value.each do |user|
        puts "user email: #{user['email']} user.inspect: #{user.inspect}"
        next if user["email"].present? && user["email"].match(/@deleted\.rdv-solidarites\.fr/)

        u = User.find_or_create_by(user.reject { |k| EXCLUDE_KEYS.include?(k) })
        puts "user trouvé ou créer (#{u})"
        users << u
      end
    else
      next if EXCLUDE_KEYS.include?(key)

      rdv_params[key] = value
    end
  end

  new_rdv = Rdv.new(rdv_params)
  new_rdv.agents = agents
  new_rdv.users = users.uniq
  new_rdv.organisation = Organisation.find(ORGANISATION_ID)

  if (existing_rdv = Rdv.find_by(new_rdv.attributes.reject { |k| EXCLUDE_KEYS.include?(k) }))
    puts "rdv existant #{existing_rdv.inspect}"
  elsif new_rdv.save
    puts "creation du RDV (#{new_rdv.id})"
  else
    puts "Problème lors de l'enregistrement du RDV #{new_rdv} : #{new_rdv.errors.full_messages.join(',')}"
  end
end
