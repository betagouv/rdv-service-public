module Anonymizer
  class ConfigError < StandardError; end

  class Config
    attr_reader :table_configs

    def initialize(raw_config)
      raise ConfigError, "top level should be a hash" unless raw_config.is_a?(Hash)

      @data = raw_config.with_indifferent_access
      raise ConfigError, "tables should be an array" unless @data[:tables].is_a?(Array)

      @table_configs = @data[:tables].map { TableConfig.new(_1) }
    end

    def table_config_by_name(table_name)
      table_configs.find { _1.table_name == table_name }
    end

    def table_names = table_configs.map(&:table_name)

    def truncated_table_configs = table_configs.select(&:truncated?)
    def truncated_table_names = truncated_table_configs.map(&:table_name)
  end

  class TableConfig
    def initialize(raw_table_config)
      raise ConfigError, "table_config should be a hash" unless raw_table_config.is_a?(Hash)

      @data = raw_table_config.with_indifferent_access
      @errors = []
      validate!
    end

    def table_name = @data[:table_name]
    def truncated? = @data.fetch(:truncated, false)
    def anonymized_column_names = @data.fetch(:anonymized_column_names, [])
    def non_anonymized_column_names = @data.fetch(:non_anonymized_column_names, [])

    private

    def validate!
      validate
      raise ConfigError, @errors.first if @errors.any?
    end

    def validate
      validate_table_name_present &&
        validate_rules_or_truncated &&
        validate_not_both_rules_and_truncated
    end

    def validate_table_name_present
      return true if table_name.present?

      @errors << "table config should contain a name"
    end

    def validate_rules_or_truncated
      return true if truncated? || anonymized_column_names.present? || non_anonymized_column_names.present?

      @errors << "table #{table_name} should have anonymization rules or be truncated"
    end

    def validate_not_both_rules_and_truncated
      return true if !truncated? || (anonymized_column_names.blank? && non_anonymized_column_names.blank?)

      @errors << "table #{table_name} cannot be truncated and have anonymization rules"
    end
  end
end
