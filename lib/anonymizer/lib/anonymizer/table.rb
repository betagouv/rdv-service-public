module Anonymizer
  class Table
    attr_reader :table_name, :table_name_without_schema

    def initialize(table_name, config: Anonymizer.default_config)
      @table_name = table_name
      @table_name_without_schema = table_name.split(".").last
      @config = config
    end

    def anonymize_records!(scope = nil)
      if table_name_without_schema.in?(config.truncated_tables_names)
        if scope.nil? || scope == scope.klass.all
          db_connection.execute("TRUNCATE #{ActiveRecord::Base.sanitize_sql(table_name)} CASCADE")
        else
          scope.delete_all
        end
      else
        anonymized_columns.each { anonymize_records_column!(scope, _1) }
      end
    end

    def anonymize_record!(record)
      anonymize_records!(record.class.where(id: record.id))
    end

    def unidentified_column_names
      all_columns = db_connection.columns(table_name).map(&:name)
      primary_key_columns = db_connection.primary_keys(table_name)
      foreign_key_columns = db_connection.foreign_keys(table_name).map { |key| key.options[:column] }
      all_columns - primary_key_columns - foreign_key_columns - anonymized_column_names - non_anonymized_column_names
    end

    private

    attr_reader :config

    def anonymize_records_column!(scope, column)
      if column.type.in?(%i[string text]) && column.null
        # Pour limiter la confusion lors de l'exploitation des données, on transforme les chaines vides en null
        blank_value = column.array ? "{}" : ""
        scope
          .where(column.name => blank_value)
          .update_all(column.name => nil) # rubocop:disable Rails/SkipsModelValidations
      end

      scope
        .where.not(column.name => nil)
        .update_all(column.name => anonymous_value(column)) # rubocop:disable Rails/SkipsModelValidations
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

    def anonymous_value(column)
      if column.type.in?(%i[string text])
        anonymous_text_value(column)
      elsif column.type == :jsonb
        Arel.sql("'{}'::jsonb") # necessary for api_calls.raw_http, non-nullable but with null default
      else
        column.default
      end
    end

    def anonymous_text_value(column)
      if column.array
        Arel.sql("'{valeur anonymisée}'") # TODO : je ne crois pas que ce soit utilisé
      elsif column.name.include?("email")
        Arel.sql("'email_anonymise_' || id || '@exemple.fr'")
      elsif column_has_uniqueness_constraint?(column)
        Arel.sql("'[valeur unique anonymisée ' || id || ']'")
      else
        "[valeur anonymisée]"
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
