# frozen_string_literal: true

# rails runner scripts/compute_organisation_stats.rb id_de_l'organisation

org = Organisation.find(ARGV[0])
puts "Cacul des statistiques pour l'organisation #{org.name} (#{org.departement})"
puts

users = org.users
puts "#{users.count} usagers pour cette organisation"

active_users = users.where.not(invitation_accepted_at: nil)
puts "dont #{active_users.count} usagers ayant validé leurs comptes"

avec_email = { sans_rdv: 0, validation_compte: [], prise_de_rdv: [], delai_rdv: [], delai_rdv_total: [], delai_rdv_effectif: [] }
sans_email = { sans_rdv: 0, validation_compte: [], prise_de_rdv: [], delai_rdv: [], delai_rdv_total: [], delai_rdv_effectif: [] }

active_users.each do |user|
  hash = if user.versions.first.changeset[:email]
           avec_email
         else
           sans_email
         end
  hash[:sans_rdv] += 1 if user.rdvs.empty?
  hash[:validation_compte] << user.invitation_accepted_at - user.created_at
  if (rdv = user.rdvs.first)
    hash[:prise_de_rdv] << rdv.created_at - user.invitation_accepted_at
    hash[:delai_rdv] << rdv.starts_at - rdv.created_at
    hash[:delai_rdv_total] << rdv.starts_at - user.created_at
  end
  if (rdv_effectue = user.rdvs.where(status: 2).first)
    hash[:delai_rdv_effectif] << rdv_effectue.starts_at - user.created_at
  end
end

puts "dont #{avec_email[:sans_rdv] + sans_email[:sans_rdv]} usagers actifs sans rendez-vous"
puts "#{sans_email[:validation_compte].size} usagers n'avaient pas de mail à la création du compte"
puts

puts "#{org.rdvs.count} rdvs pris pour cette organisation"
puts "#{org.rdvs.future.not_cancelled.count} rdvs en attente pour cette organisation"
puts "#{org.rdvs.seen.count} rdvs effectués pour cette organisation"
puts "#{org.rdvs.excused.count} rdvs annulés pour cette organisation"
puts "#{org.rdvs.notexcused.count} lapins"

puts

def display_stats(stat_name, stat_text, avec_email, sans_email)
  source_avec = avec_email[:"#{stat_name}"]
  source_sans = sans_email[:"#{stat_name}"]
  avec_email[:"#{stat_name}_average"] = source_avec.sum / source_avec.size if source_avec.size.positive?
  sans_email[:"#{stat_name}_average"] = source_sans.sum / source_sans.size if source_sans.size.positive?
  stat_average = (source_avec + source_sans).sum / (source_avec + source_sans).size if source_avec.size.positive? || source_sans.size.positive?

  puts "Délai moyen #{stat_text} : #{stat_average.fdiv(86_400).round(2)} jours" if stat_average
  puts "compte avec email : #{avec_email[:"#{stat_name}_average"].fdiv(86_400).round(2)} jours" if avec_email[:"#{stat_name}_average"]
  puts "compte sans email : #{sans_email[:"#{stat_name}_average"].fdiv(86_400).round(2)} jours" if sans_email[:"#{stat_name}_average"]
  puts
end

display_stats("validation_compte", "d'activation d'un compte", avec_email, sans_email)
display_stats("prise_de_rdv", "pour prendre un rdv", avec_email, sans_email)
display_stats("delai_rdv", "pour avoir un rdv", avec_email, sans_email)
display_stats("delai_rdv_total", "entre la création du compte et le 1er rdv", avec_email, sans_email)
display_stats("delai_rdv_effectif", "entre la création du compte et le 1er rdv effectué",avec_email, sans_email)
