# Lancer avec bundle exec rails runner scripts/initialize_calculator_index_values.rb

# rubocop:disable Rails/SkipsModelValidations
AgentsRdv.update_all(<<~SQL.squish
    readonly_rdv_starts_at = rdvs.starts_at,
    readonly_rdv_ends_at = rdvs.ends_at,
    readonly_busy_in_the_future = (rdvs.starts_at >= NOW() AND rdvs.status IN ('unknown', 'seen', 'noshow'))
  FROM rdvs WHERE rdvs.id = agents_rdvs.rdv_id
SQL
                    )
# rubocop:enable Rails/SkipsModelValidations
