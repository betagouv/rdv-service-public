require_relative "column"

module Anonymizer
  class Table
    attr_reader :table_name, :table_name_without_schema

    def initialize(table_name, config: Anonymizer.default_config)
      @table_name = table_name
      @table_name_without_schema = table_name.split(".").last
      @config = config
    end

    def anonymize_records!(arel_where = nil)
      if table_name_without_schema.in?(config.truncated_tables_names)
        if arel_where.nil?
          db_connection.execute("TRUNCATE #{ActiveRecord::Base.sanitize_sql(table_name)} CASCADE")
        else
          db_connection.execute(Arel::DeleteManager.new(arel_table).where(arel_where).to_sql)
        end
      else
        anonymized_columns.each { Anonymizer::Column.new(table_name, _1, arel_where:).anonymize! }
      end
    end

    def anonymize_record!(record)
      anonymize_records!(arel_table[:id].eq(record.id))
    end

    def unidentified_column_names
      all_columns = db_connection.columns(table_name).map(&:name)
      primary_key_columns = db_connection.primary_keys(table_name)
      foreign_key_columns = db_connection.foreign_keys(table_name).map { |key| key.options[:column] }
      all_columns - primary_key_columns - foreign_key_columns - anonymized_column_names - non_anonymized_column_names
    end

    private

    attr_reader :config

    def db_connection = ActiveRecord::Base.connection

    def arel_table
      @arel_table ||= Arel::Table.new(table_name)
    end

    def anonymized_column_names
      config.rules.dig(table_name_without_schema, :anonymized_column_names) || []
    end

    def non_anonymized_column_names
      config.rules.dig(table_name_without_schema, :non_anonymized_column_names) || []
    end

    def anonymized_columns
      db_connection.columns(table_name).select { _1.name.in?(anonymized_column_names) }
    end
  end
end
