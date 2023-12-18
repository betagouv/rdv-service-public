class Anonymizer
  def self.anonymize_all_data!
    ActiveRecord::Base.connection.tables.each do |table_name|
      anonymize_table!(table_name)
    end
  end

  def self.anonymize_user_data!
    anonymize_table!("users")
    anonymize_table!("receipts")
    anonymize_table!("rdvs")
  end

  def self.anonymize_table!(table_name)
    new(table_name).anonymize_table!
  end

  def self.anonymize_record!(record)
    new(record.class.table_name).anonymize_record!(record)
  end

  def initialize(table_name)
    @table_name = table_name
  end

  def anonymize_record!(record)
    record.class.where(id: record.id).update_all(anonymized_attributes) # rubocop:disable Rails/SkipsModelValidations
    record.reload
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def anonymize_table! # rubocop:disable Metrics/PerceivedComplexity
    if Rails.env.production? && ENV["ETL"].blank?
      raise "L'anonymisation en masse est désactivée en production pour éviter les catastrophes"
    end
    # Sanity checks supplémentaires
    # Ces variables d'envs n'ont rien à voir avec l'ETL, et ne devraient donc pas être présentes
    if ENV["DEFAULT_SMS_PROVIDER"].present?
      raise "Attention, il semble que vous êtes en train d'anonymiser des données d'une appli web"
    end

    if @table_name.in?(AnonymizerRules::TRUNCATED_TABLES)
      db_connection.execute("TRUNCATE #{ActiveRecord::Base.sanitize_sql(@table_name)}")
      return
    end

    if unidentified_column_names.present?
      raise "Les règles d'anonymisation pour les colonnes #{unidentified_column_names.join(' ')} de la table #{@table_name} n'ont pas été définies"
    end

    return if anonymized_columns.blank?

    model_class = AnonymizerRules::RULES.dig(@table_name, "class_name")&.constantize

    if model_class.nil?
      raise "Pas de modèle trouvé pour la table #{@table_name}"
    end

    anonymized_columns.each do |column|
      scope = model_class.unscoped.where.not(column.name => nil)
      if column.type.in?(%i[string text])
        scope = scope.where.not(column.name => "")
      end

      scope.update_all(column.name => anonymous_value(column)) # rubocop:disable Rails/SkipsModelValidations
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  private

  def unidentified_column_names
    all_columns = db_connection.columns(@table_name).map(&:name)
    primary_key_columns = db_connection.primary_keys(@table_name)
    foreign_key_columns = db_connection.foreign_keys(@table_name).map { |key| key.options[:column] }
    all_columns - primary_key_columns - foreign_key_columns - anonymized_column_names - non_anonymized_column_names
  end

  def anonymized_column_names
    AnonymizerRules::RULES.dig(@table_name, :anonymized_column_names) || []
  end

  def non_anonymized_column_names
    AnonymizerRules::RULES.dig(@table_name, :non_anonymized_column_names) || []
  end

  def anonymized_attributes
    anonymized_columns.to_h do |column|
      [column.name, anonymous_value(column)]
    end.symbolize_keys
  end

  def anonymized_columns
    db_connection.columns(@table_name).select do |column|
      column.name.in?(anonymized_column_names)
    end
  end

  def anonymous_value(column)
    if column.type.in?(%i[string text])
      if column_has_uniqueness_constraint?(column)
        Arel.sql("'[valeur unique anonymisée ' || id || ']'")
      else
        "[valeur anonymisée]"
      end
    else
      column.default
    end
  end

  def column_has_uniqueness_constraint?(column)
    db_connection.indexes(@table_name).select(&:unique).any? do |index|
      # il se peut que la deuxième colonne de l'index n'ai pas de contrainte d'unicité
      index.columns.first == column.name
    end
  end

  def db_connection
    ActiveRecord::Base.connection
  end
end
