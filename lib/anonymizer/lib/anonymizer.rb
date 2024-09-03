require_relative "anonymizer/version"
require_relative "anonymizer/config"
require_relative "anonymizer/table"

module Anonymizer
  class ExhaustivityError < StandardError; end

  def self.default_config
    @default_config ||= begin
      yaml_path = ENV["ANONYMIZER_CONFIG_PATH"].presence || Rails.root.join("config/anonymizer.yml")
      raw_config = YAML.safe_load_file(yaml_path)
      Config.new raw_config
    rescue Errno::ENOENT
      raise "Anonymizer config file not found at #{yaml_path}"
    end
  end

  def self.anonymize_record!(record, config: nil)
    config ||= default_config
    table_config = config.table_config_by_name(record.class.table_name)
    Table.new(table_config:).anonymize_record!(record)
  end

  def self.anonymize_records!(table_name, scope: nil, config: nil)
    config ||= default_config
    table_config = config.table_config_by_name(table_name)
    Table.new(table_config:).anonymize_records!(scope:)
  end

  def self.validate_exhaustivity!(config: nil)
    errors = exhaustivity_errors(config:)
    raise ExhaustivityError, errors.to_sentence if errors.any?
  end

  def self.exhaustivity_errors(config: nil)
    config ||= default_config
    errors = (
      ActiveRecord::Base.connection.tables.to_set -
      config.table_names.to_set
    ).map { "missing rules for table #{_1}" }
    config.table_configs.each do |table_config|
      errors += Anonymizer::Table
        .new(table_config:)
        .unidentified_column_names
        .map { "missing rule for column #{table_config.table_name}.#{_1}" }
    end
    errors
  end
end
