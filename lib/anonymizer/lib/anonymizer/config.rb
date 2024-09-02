class AnonymizerConfigError < StandardError; end

module Anonymizer
  class Config
    def initialize(raw_config)
      raise AnonymizerConfigError, "top level should be a hash" unless raw_config.is_a?(Hash)

      @data = raw_config.with_indifferent_access
      raise AnonymizerConfigError, "tables should be an array" unless @data[:tables].is_a?(Array)
    end

    def table_configs = @data[:tables].map { TableConfig.new(_1) }

    def table_config_by_name(table_name)
      table_configs.find { _1.table_name == table_name }
    end

    def table_names = table_configs.map(&:table_name)

    def truncated_table_configs = table_configs.select(&:truncated?)
    def truncated_table_names = table_table_configs.map(&:table_name)
  end

  class TableConfig
    def initialize(raw_table_config)
      raise AnonymizerConfigError, "table_config should be a hash" unless raw_table_config.is_a?(Hash)

      @data = raw_table_config.with_indifferent_access
      raise AnonymizerConfigError, "table config should contain a name" if @data[:table_name].blank?

      # TODO: check that it’s either truncated or has anon rules
    end

    def table_name = @data[:table_name]
    def truncated? = @data.fetch(:truncated, false)
    def anonymized_column_names = @data.fetch(:anonymized_column_names, [])
    def non_anonymized_column_names = @data.fetch(:non_anonymized_column_names, [])
  end
end
