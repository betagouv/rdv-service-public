# frozen_string_literal: true

class CssHexColorValidator < ActiveModel::EachValidator
  def validate_each(object, attribute, value)
    return if value =~ /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/i

    object.errors.add(attribute, (options[:message] || "doit être une couleur CSS valide (sous la forme #RRGGBB)"))
  end
end
