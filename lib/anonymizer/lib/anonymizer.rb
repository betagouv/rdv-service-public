require_relative "anonymizer/version"
require_relative "anonymizer/config"
require_relative "anonymizer/table"

module Anonymizer
  def self.default_config
    @default_config = Config.new(
      ENV["ANONYMIZER_CONFIG_PATH"].presence || Rails.root.join("config/anonymizer.yml")
    )
  end

  def self.anonymize_all_data!(schema: "rdvsp", config: default_config)
    config.rules.each_key do |table_name|
      anonymize_table!("#{schema}.#{table_name}")
    end
  end

  def self.anonymize_user_data!(config: default_config)
    anonymize_table!("users")
    anonymize_table!("receipts")
    anonymize_table!("rdvs")
    config.truncated_tables.each do |table_name|
      anonymize_table!(table_name)
    end
  end

  def self.anonymize_table!(table_name, config: default_config)
    Table.new(table_name, config:).anonymize_table!
  end

  def self.anonymize_record!(record, config: default_config)
    Table.new(record.class.table_name, config:).anonymize_record!(record)
  end

  def self.anonymize_records_in_scope!(scope, config: default_config)
    Table.new(scope.table_name, config:).anonymize_records_in_scope!(scope)
  end
end
