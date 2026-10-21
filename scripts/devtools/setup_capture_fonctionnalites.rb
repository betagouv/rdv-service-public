# Données de démonstration pour les captures d'écran de la page fonctionnalités.
# À lancer avec : bin/rails runner scripts/devtools/setup_capture_fonctionnalites.rb
#
# Idempotent, pensé pour tourner sur une base fraîchement seedée (bin/rails db:seed) :
# - un motif collectif « Réunion d’information » et un RDV collectif avec 4 participant·es ;
# - un motif « Changement d’adresse » réservé aux usager·ères invité·es, avec une
#   invitation en attente pour le premier usager du seed rdv_mairie.
#
# Affiche sur stdout les valeurs utiles au script de captures (lien public de
# l'organisation, id du RDV collectif, jeton de l'invitation).

org = Organisation.find(31) # Mairie de Sannois (seed rdv_mairie)
agent = Agent.find(37)
lieu = Lieu.find(109)
usager = User.find(10010)

service = agent.services.first

# RDV collectif avec 4 participant·es
motif_collectif = org.motifs.find_or_create_by!(name: "Réunion d’information") do |motif|
  motif.assign_attributes(
    collectif: true,
    bookable_by: :everyone,
    color: "#417dc4",
    default_duration_in_min: 60,
    service:
  )
end

noms_participantes = [
  %w[Fatou Ndiaye],
  %w[Karim Benaissa],
  %w[Marie-Pierre Lambert],
  %w[Éric Nguyen],
]

participantes = noms_participantes.map do |(prenom, nom)|
  email = "#{prenom.parameterize.first}#{nom.parameterize.tr('-', '')}@mairie.rdv.fr"
  User.find_or_create_by!(email:) do |user|
    user.assign_attributes(first_name: prenom, last_name: nom, organisations: [org])
  end
end

starts_at = Date.tomorrow.in_time_zone.change(hour: 10, min: 0)
rdv_collectif = Rdv.find_or_create_by!(motif: motif_collectif, starts_at:) do |rdv|
  rdv.assign_attributes(
    organisation: org,
    lieu:,
    agents: [agent],
    duration_in_min: 60,
    max_participants_count: 12,
    created_by: agent
  )
end
rdv_collectif.participations.where.not(user_id: participantes.map(&:id)).destroy_all
participantes.each do |user|
  rdv_collectif.participations.find_or_create_by!(user:) do |participation|
    participation.created_by = agent
  end
end

# Invitation en attente sur un motif réservé aux usager·ères invité·es
motif_sur_invitation = org.motifs.find_or_create_by!(name: "Changement d’adresse") do |motif|
  motif.assign_attributes(
    bookable_by: :agents_and_prescripteurs_and_invited_users,
    color: "#7a9dd6",
    default_duration_in_min: 30,
    service:
  )
end

plage_permamence_classique = PlageOuverture.find(17)
plage_permamence_classique.update!(motif_ids: (plage_permamence_classique.motif_ids + [motif_sur_invitation.id]).uniq)

invitation = RdvInvitation.pending.find_by(user: usager, motif: motif_sur_invitation)
if invitation.nil?
  invitation = RdvInvitation.create!(user: usager, motif: motif_sur_invitation, inviting_agent: agent, lieu:)
end

puts "PUBLIC_LINK=#{org.public_link_id}"
puts "RDV_COLLECTIF_ID=#{rdv_collectif.id}"
puts "INVITATION_TOKEN=#{invitation.reload.token}"
