module Anonymizer
  module UnsafeConcern
    extend ActiveSupport::Concern

    class_methods do
      def anonymize_all_data!(config: nil)
        config ||= default_config
        config.existing_tables.each(&:anonymize_all_records!)
      end
    end
  end
end
