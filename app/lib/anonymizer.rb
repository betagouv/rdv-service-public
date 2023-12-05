class Anonymizer
  def self.anonymize_all_data!
    models = [
      User, Receipt, Rdv, Prescripteur, Agent, SuperAdmin, Organisation, Absence,
      Lieu, Participation, PlageOuverture, WebhookEndpoint, Territory,
      AgentRole, AgentsRdv, AgentTerritorialAccessRight, AgentTerritorialRole,
    ]

    ActiveRecord::Base.connection.tables.each do |table_name|
      model_class = models.find do |model|
        model.table_name == table_name
      end
      anonymize_table!(model_class, table_name)
    end
  end

  def self.anonymize_user_data!
    anonymize_table!(User)
    anonymize_table!(Receipt)
    anonymize_table!(Rdv)
  end

  def self.anonymize_table!(model_class, table_name)
    new(model_class, table_name).anonymize_table!
  end

  def self.anonymize_record!(record)
    new(record.class).anonymize_record!(record)
  end

  def initialize(model_class, table_name = nil)
    @model_class = model_class
    @table_name = table_name || model_class.table_name
  end

  def anonymize_record!(record)
    record.update_columns(anonymized_attributes) # rubocop:disable Rails/SkipsModelValidations
  end

  def anonymize_table!
    raise "L'anonymisation en masse est désactivée en production pour éviter les catastrophes" if Rails.env.production?

    if @table_name.in?(AnonymizerRules::TRUNCATED_TABLES)
      db_connection.execute("TRUNCATE #{@table_name.sanitize_sql}")
      return
    end

    if unidentified_column_names.present?
      raise "Les règles d'anonymisation pour les colonnes #{unidentified_column_names.join(' ')} de la table #{@table_name} n'ont pas été définies"
    end

    if anonymized_attributes.present?
      if @model_class.nil?
        raise "Pas de modèle trouvé pour la table #{@table_name}"
      end

      @model_class.unscoped.update_all(anonymized_attributes) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  private

  def unidentified_column_names
    @unidentified_column_names ||= non_key_column_names - anonymized_column_names.map(&:to_s) - non_anonymized_column_names.map(&:to_s)
  end

  def non_key_column_names
    db_connection.columns(@table_name).map(&:name) - foreign_key_column_names - primary_key_column_name
  end

  def foreign_key_column_names
    db_connection.foreign_keys(@table_name).map do |key|
      key.options[:column]
    end
  end

  def primary_key_column_name
    db_connection.primary_keys(@table_name)
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
      if column_has_unicity_constraint?(column)
        Arel.sql("CASE WHEN #{column.name.sanitize_sql} IS NULL THEN NULL ELSE '[valeur unique anonymisée ' || id || ']' END")
      else
        "[valeur anonymisée]"
      end
    else
      column.default
    end
  end

  def column_has_unicity_constraint?(column)
    db_connection.indexes(@table_name).select(&:unique).find do |index|
      # il se peut que la deuxième colonne de l'index n'ai pas de contrainte d'unicité
      index.columns.first == column.name
    end
  end

  def db_connection
    ActiveRecord::Base.connection
  end
end
