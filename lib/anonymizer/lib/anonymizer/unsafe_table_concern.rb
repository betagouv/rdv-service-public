module Anonymizer
  module UnsafeTableConcern
    def anonymize_all_records!
      if table_name_without_schema.in?(config.truncated_tables_names)
        db_connection.execute("TRUNCATE #{ActiveRecord::Base.sanitize_sql(table_name)} CASCADE")
        # elsif unidentified_column_names.present?
        #   raise "Les règles d'anonymisation pour les colonnes #{unidentified_column_names.join(' ')} de la table #{table_name} n'ont pas été définies"
      elsif anonymized_columns.blank?
        nil
      else
        anonymized_columns.each { anonymize_whole_column!(_1) }
      end
    end

    def anonymize_whole_column!(column)
      if column.type.in?(%i[string text]) && column.null # On vérifie que la colonne est nullable
        # Pour limiter la confusion lors de l'exploitation des données, on transforme les chaines vides en null
        value = column.array ? "{}" : ""
        db_connection.execute "UPDATE #{table_name} SET #{column.name} = NULL WHERE #{column.name} = '#{value}'"
      end

      db_connection.execute "UPDATE #{table_name} SET #{column.name} = #{anonymous_value(column, quote_value: true)} WHERE #{column.name} IS NOT NULL"
    end
  end
end
