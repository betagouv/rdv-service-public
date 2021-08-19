# frozen_string_literal: true

# rails runner scripts/compute_organisation_stats.rb organisation_id

org = Organisation.find(ARGV[0])
# We take only users that were created before 26 days ago to have significant stats
users_of_interest = org.users.where("created_at < ?", 26.days.ago)
users_data = []

users_of_interest.each do |user|
  result = {}
  result[:with_email] = user.versions.first.changeset[:email].present?
  result[:oriented] = user.rdvs.where(status: 2).any?
  result[:invitation_accepted] = user.invitation_accepted_at.present?
  result[:with_rdvs] = user.rdvs.present?
  if user.invitation_accepted_at
    result[:time_to_accept] = user.invitation_accepted_at - user.created_at
  end
  result[:rdvs] = []
  user.rdvs.each do |rdv|
    rdv_result = {}
    rdv_result[:created_by] = rdv.created_by
    rdv_result[:status] = rdv.status
    if rdv.starts_at
      rdv_result[:time_between_rdv_start_and_rdv_creation] = rdv.starts_at - rdv.created_at
      rdv_result[:time_between_user_creation_and_rdv_start] = rdv.starts_at - user.created_at
    end
    result[:rdvs] << rdv_result
  end
  users_data << result
end

def percentage(count, total)
  "#{(count / total.to_f).round(2) * 100} %"
end

puts "Cacul des statistiques pour l'organisation #{org.name} (#{org.departement})"
puts

puts "#{org.users.count} usagers au total pour cette organisation."
puts

puts "#{users_of_interest.count} usagers ont été créés il y a plus de 26 jours."
puts

puts

puts "Sur ces usagers créés il y a plus de 26 jours: "
puts

users_with_email_count = users_data.pluck(:with_email).count(true)
users_without_email_count = users_data.pluck(:with_email).count(false)
puts "#{users_with_email_count} utilisateurs créés avec email soit #{percentage(users_with_email_count, users_of_interest.count)}."
puts

puts "#{users_without_email_count} utilisateurs créés avec email soit #{percentage(users_without_email_count, users_of_interest.count)}."
puts

puts

["avec et sans email (total)", "avec email", "sans email"].each do |scenario|
  users = case scenario
          when "avec et sans email (total)"
            users_data
          when "avec email"
            users_data.select { |u| u[:with_email] }
          when "sans email"
            users_data.reject { |u| u[:with_email] }
          end

  puts
  puts "----------------------------------"
  puts "----------------------------------"
  puts "Pour les utilisateurs #{scenario}:"
  puts "----------------------------------"
  puts "----------------------------------"
  puts

  puts
  puts "Nombre d'utilisateurs: #{users.count}"
  puts

  users_with_invitation_accepted_count = users.pluck(:invitation_accepted).count(true)
  puts
  puts "#{users_with_invitation_accepted_count} utilisateurs ayant accepté l'invtation de création de compte soit  #{percentage(users_with_invitation_accepted_count, users.count)}."
  puts

  users_with_rdvs_count = users.pluck(:with_rdvs).count(true)
  puts
  puts "#{users_with_rdvs_count} utilisateurs avec un RDV de créé soit #{percentage(users_with_rdvs_count, users.count)}."
  puts

  first_rdv_created_by_users_count = users.count { |user| user[:rdvs].first&.dig(:created_by) == "user" }
  first_rdv_created_by_agents_count = users.count { |user| user[:rdvs].first&.dig(:created_by) == "agent" }
  puts
  puts "#{first_rdv_created_by_users_count} utilisateurs qui ont créé leur 1er  RDV eux-même soit #{percentage(first_rdv_created_by_users_count, users.count)} du nombre d'utilisateurs et " \
       "#{percentage(first_rdv_created_by_users_count, users_with_rdvs_count)} des utilisateurs avec un RDV de créé."
  puts

  puts "#{first_rdv_created_by_agents_count} utilisateurs dont l'agent a créé le 1er RDV soit #{percentage(first_rdv_created_by_agents_count, users.count)} du nombre d'utilisateurs et " \
       "#{percentage(first_rdv_created_by_agents_count, users_with_rdvs_count)} des utilisateurs avec un RDV de créé."
  puts

  rdv_seen_count = users.pluck(:oriented).count(true)
  puts
  puts "#{rdv_seen_count} utilisateurs avec un RDV d'effectué soit #{percentage(rdv_seen_count, users.count)} du nombre d'utilisateurs et " \
       "#{percentage(rdv_seen_count, users_with_rdvs_count)} des utilisateurs avec un RDV de créé."
  puts

  users_with_rdv_seen_in_less_than_26_days_count = users.count do |user|
    user[:rdvs].any? { |rdv| rdv[:status] == "seen" && rdv[:time_between_user_creation_and_rdv_start] <= 26.days }
  end
  puts
  puts "#{users_with_rdv_seen_in_less_than_26_days_count} utilisateurs avec un RDV fait moins de 26 jours après la création du compte soit " \
       "#{percentage(users_with_rdv_seen_in_less_than_26_days_count, users.count)} du nombre d'utilisateurs " \
       " et #{percentage(users_with_rdv_seen_in_less_than_26_days_count, rdv_seen_count)} des utilisateurs avec un RDV d'effectué."
  puts

  users_with_rdv_excused_count = users.count do |user|
    user[:rdvs].any? { |rdv| rdv[:status] == "excused" }
  end
  users_with_rdv_cancelledbyagent_count = users.count do |user|
    user[:rdvs].any? { |rdv| rdv[:status] == "revoked" }
  end
  users_with_rdv_noshow_count = users.count do |user|
    user[:rdvs].any? { |rdv| rdv[:status] == "noshow" }
  end
  users_absent_to_a_rdv_count = users_with_rdv_excused_count + users_with_rdv_cancelledbyagent_count + users_with_rdv_noshow_count
  puts
  puts "#{users_with_rdv_excused_count} utilisateurs ont vu leur RDV annulé par un agent soit #{percentage(users_with_rdv_excused_count, users.count)} du nombre d'utilisateurs."
  puts

  puts "#{users_with_rdv_excused_count} utilisateurs ont été absents à un RDV mais ont été excusés soit #{percentage(users_with_rdv_excused_count, users.count)} du nombre d'utilisateurs."
  puts

  puts "#{users_with_rdv_noshow_count} utilisateurs ont été absents à un RDV sans être excusés soit #{percentage(users_with_rdv_excused_count, users.count)} du nombre d'utilisateurs."
  puts

  puts "#{users_absent_to_a_rdv_count} utilisateurs au total ont été absents à un RDV (excusé au non) soit " \
       "#{percentage(users_absent_to_a_rdv_count, users.count)} du nombre d'utilisateurs " \
       "et #{percentage(users_absent_to_a_rdv_count, users_with_rdvs_count)} des utilisateurs ayant des RDVs de créés."
  puts

  times_between_user_creation_and_rdv_start = users.map do |user|
    user[:rdvs].find do |rdv|
      rdv[:status] == "seen"
    end&.dig(:time_between_user_creation_and_rdv_start)
  end.compact
  average_time_between_user_creation_and_rdv_start = \
    (times_between_user_creation_and_rdv_start.sum / times_between_user_creation_and_rdv_start.length.to_f) / (24 * 60 * 60)
  puts
  puts "#{average_time_between_user_creation_and_rdv_start.round(2)} jours en moyenne entre le moment où l'utilisateur est créé et " \
       "le moment où le rdv est effectué pour les RDV effectués."
  puts
end
