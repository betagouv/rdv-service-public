# frozen_string_literal: true

# Le principe c'est de pouvoir extraire d'un environnement, d'une base de
# donnée, une structure de donnée à partir d'un agent pour pouvoir le recharger
# dans une nouvelle base de donnée, un nouvel environnement.
#
# La structure la plus simple semble être json ou yaml...

if ARGV.first.blank?
  puts "Aucun identifiant d'agent"
  exit 0
end

begin
  agent = Agent.find(ARGV.first)
rescue StandardError
  puts "Aucun agent trouvé avec l'ID #{ARGV.first}"
  exit 0
end

rdvs = agent.rdvs
puts rdvs.as_json(
  include: %i[motif users lieu]
).to_json
