class AntsPreDemandeNumberFormatValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank? || value.upcase.match?(/\A[A-Z0-9]{10}\z/)

    record.errors.add(attribute, :invalid_format)
  end
end
