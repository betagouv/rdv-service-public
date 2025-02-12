class AntsPreDemandeNumberFormatValidator < ActiveModel::EachValidator
  REGEX = /\A[A-Z0-9]{10}\z/

  def validate_each(record, attribute, value)
    return if record.errors[attribute]&.include?(:invalid_format)
    # évite les doublons d’erreurs si la validation est appellée plusieurs fois

    return if value.blank? || value.upcase.match?(REGEX)

    record.errors.add(attribute, :invalid_format)
  end
end
