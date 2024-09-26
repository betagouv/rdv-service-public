require_relative "column"

module Anonymizer
  class PartialTableTruncate < StandardError; end

  class Table
    attr_reader :table_config

    delegate :table_name, :truncated?, :anonymized_column_names, :non_anonymized_column_names, to: :table_config

    def initialize(table_config:)
      @table_config = table_config
    end

    def anonymize_records!(scope: nil)
      if scope.present? && !scope.is_a?(Arel::Nodes::Node)
        raise ArgumentError, "scope (#{scope.class}) should be an arel node"
      end

      if truncated? && scope.present?
        raise PartialTableTruncate, "cannot anonymize scoped records in a table that should be truncated"
      end

      if truncated?
        Anonymizer.db_connection.execute("TRUNCATE #{ActiveRecord::Base.sanitize_sql(table_name)} CASCADE")
      else
        anonymized_columns.each do |column|
          Anonymizer::Column.new(table_name, column, scope:).anonymize!
        end
      end
    end

    def anonymize_record!(record)
      raise PartialTableTruncate, "cannot anonymize single record in a table that should be truncated" if truncated?

      anonymize_records!(scope: arel_table[:id].eq(record.id))
    end

    def unidentified_column_names
      return [] if truncated?

      all_columns = Anonymizer.db_connection.columns(table_name).map(&:name)
      primary_key_columns = Anonymizer.db_connection.primary_keys(table_name)
      foreign_key_columns = Anonymizer.db_connection.foreign_keys(table_name).map { |key| key.options[:column] }
      all_columns - primary_key_columns - foreign_key_columns - anonymized_column_names - non_anonymized_column_names
    end

    def exists?
      Anonymizer.db_connection.table_exists?(table_name)
    end

    private

    def arel_table
      @arel_table ||= Arel::Table.new(table_name)
    end

    def anonymized_columns
      Anonymizer.db_connection.columns(table_name).select { _1.name.in?(anonymized_column_names) }
    end
  end
end
