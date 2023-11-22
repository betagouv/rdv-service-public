module Anonymizable
  extend ActiveSupport::Concern

  def anonymize_personal_data_columns!
    update_columns(self.class.anonymized_attributes) # rubocop:disable Rails/SkipsModelValidations
  end

  class_methods do
    def anonymize_all!(scope)
      raise "L'anonymisation en masse est désactivée en production pour éviter les catastrophes" if Rails.env.production?

      scope.update_all(anonymized_attributes) # rubocop:disable Rails/SkipsModelValidations
    end

    def anonymized_attributes
      personal_data_columns = columns.select do |column|
        column.name.in?(personal_data_column_names)
      end

      personal_data_columns.to_h do |column|
        [column.name, anonymous_value(column)]
      end
    end

    def anonymous_value(column)
      case column.type.to_sym
      when :string, :text
        "[valeur anonymisée]"
      when :date
        column.null ? nil : Date.new(1900, 1, 1)
      when :integer
        column.null ? nil : 0
      else
        raise "Don't know how to anonymize column #{column.name} (#{column.type})"
      end
    end
  end
end
