module Anonymizable
  def anonymize_personal_data_columns!
    personal_data_columns = self.class.columns.select do |column|
      column.name.in?(self.class.personal_data_column_names)
    end

    anonymized_attributes = personal_data_columns.to_h do |column|
      [column.name, anonymous_value(column)]
    end

    update_columns(anonymized_attributes) # rubocop:disable Rails/SkipsModelValidations
  end

  private

  def anonymous_value(column)
    if column.type.in?(%i[string text])
      "valeur anonymisée"
    end
  end
end
