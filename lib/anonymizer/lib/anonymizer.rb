require_relative "anonymizer/version"
require_relative "anonymizer/config"
require_relative "anonymizer/table"

module Anonymizer
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
    Table.new(record.class.table_name, config:).anonymize_record!(record)
  end

  def self.anonymize_records!(table_name, arel_where: nil, config: nil)
    config ||= default_config
    Table.new(table_name, config:).anonymize_records!(arel_where)
  end

  def self.validate_all_columns_defined!
    # TODO
    # elsif unidentified_column_names.present?
    #   raise "Les règles d'anonymisation pour les colonnes #{unidentified_column_names.join(' ')} de la table #{table_name} n'ont pas été définies"
  end
end
