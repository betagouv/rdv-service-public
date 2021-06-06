# frozen_string_literal: true

module HasPhoneNumberConcern
  extend ActiveSupport::Concern

  included do
    validate :validate_phone_number
    before_save :format_phone_number
  end

  def validate_phone_number
    errors.add(:phone_number, :invalid) if phone_number.present? && !phone_number_is_valid?
  end

  def format_phone_number
    self.phone_number_formatted = phone_number_is_valid? ? Phonelib.parse(phone_number).e164 : nil
  end

  def phone_number_is_valid?
    return false if phone_number.blank?

    parsed_number = Phonelib.parse(phone_number)
    country_codes = %i[FR GP GF MQ RE YT]
    # See issue #1471. We want to allow:
    # * international (e164) phone numbers
    # * “french format” (ten digits with a leading 0)
    # However, we need to special-case some ten-digit numbers,
    # because the ARCEP assigns some blocks of "O6 XX XX XX XX" numbers to DROM operators.
    # Guadeloupe | GP | +590 | 0690XXXXXX, 0691XXXXXX
    # Guyane     | GF | +594 | 0694XXXXXX
    # Martinique | MQ | +596 | 0696XXXXXX, 0697XXXXXX
    # Réunion    | RE | +262 | 0692XXXXXX, 0693XXXXXX
    # Mayotte    | YT | +262 | 0692XXXXXX, 0693XXXXXX
    # Cf: Plan national de numérotation téléphonique,
    # https://www.arcep.fr/uploads/tx_gsavis/05-1085.pdf  “Numéros mobiles à 10 chiffres”, page 6
    parsed_number.valid? || country_codes.any?{ parsed_number.valid_for_country? _1 }
  end

  def phone_number_formatted
    # overrides getter to make sure value is synced with phone_number
    format_phone_number
    super
  end
end
