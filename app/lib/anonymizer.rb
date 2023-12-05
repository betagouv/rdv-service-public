class Anonymizer
  def self.anonymize_all_data!
    models = [
      User, Receipt, Rdv, Prescripteur, Agent, SuperAdmin, Organisation, Absence,
      Lieu, Participation, PlageOuverture, WebhookEndpoint,
    ]

    tables_without_anonymization_rules = ActiveRecord::Base.connection.tables - models.map(&:table_name)
    # TODO: uncomment this
    # if tables_without_anonymization_rules.any?
    #   raise "Les règles d'anonymisation ne sont pas définitions pour les tables #{tables_without_anonymization_rules.join(' ')}"
    # end

    models.each do |model_class|
      anonymize_table!(model_class)
    end
  end

  def self.anonymize_user_data!
    anonymize_table!(User)
    anonymize_table!(Receipt)
    anonymize_table!(Rdv)
  end

  def self.anonymize_table!(model_class)
    new(model_class).anonymize_table!
  end

  def self.anonymize_record!(record)
    new(record.class).anonymize_record!(record)
  end

  def initialize(model_class)
    @model_class = model_class
  end

  def anonymize_record!(record)
    anonymize_in_scope(@model_class.where(id: record.id))
    record.reload
  end

  def anonymize_table!
    raise "L'anonymisation en masse est désactivée en production pour éviter les catastrophes" if Rails.env.production?

    unidentified_column_names = @model_class.columns.map(&:name) - foreign_key_column_names - primary_key_column_name - anonymized_column_names.map(&:to_s) - non_anonymized_column_names.map(&:to_s)
    if unidentified_column_names.present?
      raise "Les règles d'anonymisation pour les colonnes #{unidentified_column_names.join(' ')} de la table #{@model_class.table_name} n'ont pas été définies"
    end

    anonymize_in_scope(@model_class.unscoped)
  end

  private

  def foreign_key_column_names
    @model_class.connection.foreign_keys(@model_class.table_name).map do |key|
      key.options[:column]
    end
  end

  def primary_key_column_name
    @model_class.connection.primary_keys(@model_class.table_name)
  end

  def anonymized_column_names
    AnonymizerRules::RULES[@model_class.table_name][:anonymized_column_names]
  end

  def non_anonymized_column_names
    AnonymizerRules::RULES[@model_class.table_name][:non_anonymized_column_names]
  end

  def anonymize_in_scope(scope)
    scope.update_all(anonymized_attributes) # rubocop:disable Rails/SkipsModelValidations
  end

  def anonymized_attributes
    anonymized_columns.to_h do |column|
      [column.name, anonymous_value(column)]
    end.symbolize_keys
  end

  def anonymized_columns
    @model_class.columns.select do |column|
      column.name.in?(anonymized_column_names)
    end
  end

  def anonymous_value(column)
    if column.type.in?(%i[string text])
      if column_has_unicity_constraint?(column)
        Arel.sql("CASE WHEN #{column.name} IS NULL THEN NULL ELSE '[valeur unique anonymisée ' || id || ']' END")
      else
        "[valeur anonymisée]"
      end
    else
      column.default
    end
  end

  def column_has_unicity_constraint?(column)
    @model_class.connection.indexes(@model_class.table_name).select(&:unique).find do |index|
      # il se peut que la deuxième colonne de l'index n'ai pas de contrainte d'unicité
      index.columns.first == column.name
    end
  end
end
