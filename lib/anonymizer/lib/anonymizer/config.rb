class AnonymizerConfigError < StandardError; end

module Anonymizer
  class Config
    def initialize(raw_config)
      raise AnonymizerConfigError, "top level should be a hash" unless raw_config.is_a?(Hash)

      @data = raw_config.with_indifferent_access
      raise AnonymizerConfigError, "rules should be a hash" unless @data[:rules].is_a?(Hash)
      raise AnonymizerConfigError, "truncated_tables should be an array" unless @data[:truncated_tables].is_a?(Array)
    end

    def rules = @data[:rules]

    def truncated_tables_names = @data[:truncated_tables]

    def truncated_tables
      @truncated_tables ||= truncated_tables_names
        .select { ActiveRecord::Base.connection.table_exists?(_1) }
        .map { Table.new(_1, config: self) }
    end

    def existing_tables
      @existing_tables ||= rules
        .keys
        .select { ActiveRecord::Base.connection.table_exists?(_1) }
        .map { Table.new(_1, config: self) }
    end
  end
end
