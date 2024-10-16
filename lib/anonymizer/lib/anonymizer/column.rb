module Anonymizer
  class Column
    attr_reader :column, :table_name, :scope

    def initialize(table_name, column, scope: nil)
      @table_name = table_name
      @column = column
      @scope = scope
    end

    def anonymize!
      if column.type.in?(%i[string text]) && column.null
        # Pour limiter la confusion lors de l'exploitation des données, on transforme les chaines vides en null
        blank_value = column.array ? "{}" : ""
        update where: arel_table[column.name].eq(blank_value), value: nil
      end

      update where: arel_table[column.name].not_eq(nil), value: anonymous_value
    end

    private

    def column_name = column.name

    def arel_table
      @arel_table ||= Arel::Table.new(table_name)
    end

    def update(where:, value:)
      Anonymizer.db_connection.execute(
        Arel::UpdateManager
          .new(arel_table)
          .where(scope ? scope.and(where) : where)
          .set(arel_table[column.name] => value)
          .to_sql
      )
    end

    def anonymous_value
      if column.type.in?(%i[string text])
        anonymous_text_value
      elsif column.type == :jsonb
        Arel.sql("'{}'::jsonb") # necessary for api_calls.raw_http, non-nullable but with null default
      else
        column.default
      end
    end

    def anonymous_text_value
      if column.array
        Arel.sql("'{valeur anonymisée}'")
        # TODO : je ne crois pas que ce soit utilisé et c’est ambigu
        # cela laisse penser qu’il y avait toujours une et une seule valeur avant l’anonymisation
      elsif column.name.include?("email")
        Arel.sql("'email_anonymise_' || id || '@exemple.fr'")
      else
        Arel.sql("'[valeur unique anonymisée ' || id || ']'")
      end
    end
  end
end
