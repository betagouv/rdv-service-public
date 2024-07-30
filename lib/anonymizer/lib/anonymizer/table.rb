module Anonymizer
  class Table
    attr_reader :table_name, :table_name_without_schema

    def initialize(table_name, config: Anonymizer.default_config)
      @table_name = table_name
      @table_name_without_schema = table_name.split(".").last
      @config = config
    end

    def anonymize_record!(record)
      record.class.where(id: record.id).update_all(anonymized_attributes) # rubocop:disable Rails/SkipsModelValidations
      record.reload
    end

    def anonymize_records_in_scope!(scope)
      scope.update_all(anonymized_attributes) # rubocop:disable Rails/SkipsModelValidations
    end

    private

    attr_reader :config

    def unidentified_column_names
      all_columns = db_connection.columns(table_name).map(&:name)
      primary_key_columns = db_connection.primary_keys(table_name)
      foreign_key_columns = db_connection.foreign_keys(table_name).map { |key| key.options[:column] }
      all_columns - primary_key_columns - foreign_key_columns - anonymized_column_names - non_anonymized_column_names
    end

    def anonymized_column_names
      config.rules.dig(table_name_without_schema, :anonymized_column_names) || []
    end

    def non_anonymized_column_names
      config.rules.dig(table_name_without_schema, :non_anonymized_column_names) || []
    end

    def anonymized_attributes
      anonymized_columns.to_h do |column|
        [column.name, anonymous_value(column)]
      end.symbolize_keys
    end

    def anonymized_columns
      db_connection.columns(table_name).select do |column|
        column.name.in?(anonymized_column_names)
      end
    end

    def anonymous_value(column, quote_value: false)
      if column.type.in?(%i[string text])
        anonymous_text_value(column, quote_value)
      elsif column.type == :jsonb
        Arel.sql("'{}'::jsonb") # necessary for api_calls.raw_http, non-nullable but with null default
      else
        quote_value ? db_connection.quote(column.default) : column.default
      end
    end

    def anonymous_text_value(column, quote_value)
      if column.array
        Arel.sql("'{valeur anonymisée}'")
      elsif column.name.include?("email")
        Arel.sql("'email_anonymise_' || id || '@exemple.fr'")
      elsif column_has_uniqueness_constraint?(column)
        Arel.sql("'[valeur unique anonymisée ' || id || ']'")
      else
        quote_value ? db_connection.quote("[valeur anonymisée]") : "[valeur anonymisée]"
      end
    end

    def column_has_uniqueness_constraint?(column)
      db_connection.indexes(table_name).select(&:unique).any? do |index|
        # il se peut que la deuxième colonne de l'index n'ai pas de contrainte d'unicité
        index.columns.first == column.name
      end
    end

    def db_connection
      ActiveRecord::Base.connection
    end
  end
end
