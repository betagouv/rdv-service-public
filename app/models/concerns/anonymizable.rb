module Anonymizable
  extend ActiveSupport::Concern

  def anonymize_columns!
    update_columns(self.class.anonymized_attributes) # rubocop:disable Rails/SkipsModelValidations
  end

  class_methods do
    def anonymized_column_names
      raise "This method should be implemented to list all the columns that need to be anonymized"
    end

    # Liste des données qui ne seront pas anonymisées
    def non_anonymized_column_names
      []
    end

    def anonymize_all!
      raise "L'anonymisation en masse est désactivée en production pour éviter les catastrophes" if Rails.env.production?

      unidentified_column_names = columns.map(&:name) - anonymized_column_names.map(&:to_s) - non_anonymized_column_names.map(&:to_s)
      if unidentified_column_names.present?
        raise "Les règles d'anonymisation pour les colonnes #{unidentified_column_names.join(', ')} de la table #{table_name} n'ont pas été définies"
      end

      unscoped.update_all(anonymized_attributes) # rubocop:disable Rails/SkipsModelValidations
    end

    def anonymized_attributes
      personal_data_columns = columns.select do |column|
        column.name.in?(anonymized_column_names)
      end

      personal_data_columns.to_h do |column|
        [column.name, anonymous_value(column)]
      end.symbolize_keys
    end

    def anonymous_value(column)
      if column.type.in?(%i[string text])
        "[valeur anonymisée]"
      else
        column.default
      end
    end
  end
end
