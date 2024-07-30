module Anonymizer
  module UnsafeConcern
    def self.anonymize_all_data!(config: nil)
      config ||= default_config
      config.existing_tables.each(&:anonymize_all_records!)
    end
  end
end
