require_relative "anonymizer/version"
require_relative "anonymizer/config"
require_relative "anonymizer/table"

module Anonymizer
  def self.default_config
    @default_config ||= begin
      yaml_path = ENV["ANONYMIZER_CONFIG_PATH"].presence || Rails.root.join("config/anonymizer.yml")
      raw_config = YAML.safe_load(File.read(yaml_path))
      Config.new raw_config
    rescue Errno::ENOENT
      raise "Anonymizer config file not found at #{yaml_path}"
    end
  end

  def self.anonymize_all_data!(schema: "public", config: nil)
    config ||= default_config
    config.rules.each_key do |table_name|
      anonymize_table!("#{schema}.#{table_name}", config:)
    end
  end

  def self.anonymize_user_data!(config: nil)
    config ||= default_config
    anonymize_table!("users")
    anonymize_table!("receipts")
    anonymize_table!("rdvs")
    config.truncated_tables.each do |table_name|
      anonymize_table!(table_name, config:)
    end
  end

  def self.anonymize_table!(table_name, config: nil)
    config ||= default_config
    Table.new(table_name, config:).anonymize_table!
  end

  def self.anonymize_record!(record, config: nil)
    config ||= default_config
    Table.new(record.class.table_name, config:).anonymize_record!(record)
  end

  def self.anonymize_records_in_scope!(scope, config: nil)
    config ||= default_config
    Table.new(scope.table_name, config:).anonymize_records_in_scope!(scope)
  end
end
