require_relative "column"

module Anonymizer
  class ScopeError < StandardError; end
  class PartialTableTruncate < StandardError; end

  class Table
    attr_reader :table_config

    delegate :table_name, :truncated?, :anonymized_column_names, :non_anonymized_column_name, to: :table_config

    def initialize(table_config:)
      @table_config = table_config
    end

    def anonymize_records!(scope: nil)
      raise ScopeError, "scope (#{scope.class}) should be an arel" if scope.present? && !scope.is_a?(Arel::Nodes::Node)

      raise PartialTableTruncate, "cannot anonymize scoped records in a table that should be truncated" if truncated? && scope.present?

      if truncated?
        db_connection.execute("TRUNCATE #{ActiveRecord::Base.sanitize_sql(table_name)} CASCADE")
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
      all_columns = db_connection.columns(table_name).map(&:name)
      primary_key_columns = db_connection.primary_keys(table_name)
      foreign_key_columns = db_connection.foreign_keys(table_name).map { |key| key.options[:column] }
      all_columns - primary_key_columns - foreign_key_columns - anonymized_column_names - non_anonymized_column_names
    end

    def exists?
      ActiveRecord::Base.connection.table_exists?(table_name)
    end

    private

    def db_connection = ActiveRecord::Base.connection

    def arel_table
      @arel_table ||= Arel::Table.new(table_name)
    end

    def anonymized_columns
      db_connection.columns(table_name).select { _1.name.in?(anonymized_column_names) }
    end
  end
end
