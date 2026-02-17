Anonymizer.anonymize_records!("users")
Anonymizer.anonymize_records!("receipts")
Anonymizer.anonymize_records!("rdvs")

Anonymizer.default_config.truncated_table_configs
  .map { Anonymizer::Table.new(table_config: _1) }
  .select(&:exists?)
  .each(&:anonymize_records!)
