# Lancer avec bundle exec rails runner scripts/initialize_calculator_index_values.rb

# rubocop:disable Rails/SkipsModelValidations
AgentsRdv.update_all <<~SQL.squish
  calculator_rdv_starts_at = rdvs.starts_at,
    calculator_rdv_ends_at = rdvs.ends_at,
    calculator_rdv_not_cancelled_and_in_the_future = (rdvs.ends_at >= NOW() AND rdvs.status IN ('unknown', 'seen', 'noshow'))
  FROM rdvs WHERE rdvs.id = agents_rdvs.rdv_id
SQL

# rubocop:enable Rails/SkipsModelValidations
