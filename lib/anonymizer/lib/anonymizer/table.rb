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

  # rubocop:disable Metrics/CyclomaticComplexity
  def anonymize_table! # rubocop:disable Metrics/PerceivedComplexity
    if Rails.env.production? && ENV["ETL"].blank?
      raise "L'anonymisation en masse est désactivée en production pour éviter les catastrophes"
    end
    # Sanity checks supplémentaires
    # Ces variables d'envs n'ont rien à voir avec l'ETL, et ne devraient donc pas être présentes
    if !Rails.env.development? && (ENV["HOST"].present? || ENV["DEFAULT_SMS_PROVIDER"].present?)
      raise "Attention, il semble que vous êtes en train d'anonymiser des données d'une appli web"
    end

    if table_name_without_schema.in?(config.truncated_tables)
      db_connection.execute("TRUNCATE #{ActiveRecord::Base.sanitize_sql(table_name)} CASCADE")
      return
    end

    if unidentified_column_names.present?
      raise "Les règles d'anonymisation pour les colonnes #{unidentified_column_names.join(' ')} de la table #{table_name} n'ont pas été définies"
    end

    return if anonymized_columns.blank?

    anonymized_columns.each { |column| anonymize_column(column, table_name) }
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  private

  attr_reader :config

  def anonymize_column(column, table)
    if column.type.in?(%i[string text]) && column.null # On vérifie que la colonne est nullable
      # Pour limiter la confusion lors de l'exploitation des données, on transforme les chaines vides en null
      value = column.array ? "{}" : ""
      db_connection.execute("UPDATE #{table} SET #{column.name} = NULL WHERE #{column.name} = '#{value}'")
    end

    db_connection.execute("UPDATE #{table} SET #{column.name} = #{anonymous_value(column, quote_value: true)} WHERE #{column.name} IS NOT NULL")
  end

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
