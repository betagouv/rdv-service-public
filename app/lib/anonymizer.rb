# frozen_string_literal: true

class Anonymizer
  def self.anonymize_all_data!
    anonymize_user_data!
    anonymize_table!(Prescripteur)
    anonymize_table!(Agent)
    anonymize_table!(SuperAdmin)
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
    new(record.class).anonymize_record!
  end

  def initialize(model_class)
    @model_class = model_class
  end

  def anonymize_record!(record)
    anonymize_in_scope(@model_class.where(id: record.id))
  end

  def anonymize_table!
    raise "L'anonymisation en masse est désactivée en production pour éviter les catastrophes" if Rails.env.production?

    unidentified_column_names = @model_class.columns.map(&:name) - @model_class.anonymized_column_names.map(&:to_s) - @model_class.non_anonymized_column_names.map(&:to_s)
    if unidentified_column_names.present?
      raise "Les règles d'anonymisation pour les colonnes #{unidentified_column_names.join(', ')} de la table #{@model_class.table_name} n'ont pas été définies"
    end

    anonymize_in_scope(@model_class.unscoped)
  end

  private

  def anonymize_in_scope(scope)
    @model_class.transaction do
      scope.update_all(anonymized_attributes) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def anonymized_attributes
    anonymized_columns.to_h do |column|
      [column.name, anonymous_value(column)]
    end.symbolize_keys
  end

  def anonymized_columns
    @model_class.columns.select do |column|
      column.name.in?(@model_class.anonymized_column_names)
    end
  end

  def anonymous_value(column)
    if column.type.in?(%i[string text])
      if column.name.in?(columns_with_unicity_constraint_names)
        Arel.sql("'[valeur unique anonymisée ' || id || ']'")
      else
        "[valeur anonymisée]"
      end
    else
      column.default
    end
  end

  def columns_with_unicity_constraint_names
    @model_class.connection.indexes(@model_class.table_name).select(&:unique).map do |index|
      index.columns.first
    end.uniq.compact
  end
end
