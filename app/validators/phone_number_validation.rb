module PhoneNumberValidation
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
  COUNTRY_CODES = %i[FR GP GF MQ RE YT].freeze

  def self.parsed_number(phone_number)
    return if phone_number.blank?

    COUNTRY_CODES.each do |country_code|
      parsed_attempt = Phonelib.parse(phone_number, country_code)
      return parsed_attempt if parsed_attempt.valid?
    end

    nil
  end

  def self.number_is_mobile?(phone_number)
    types = parsed_number(phone_number)&.types
    types&.include?(:mobile)
  end

  # Concern to include in application models
  # Models need to have a :phone_number and a :phone_number_formatted attributes
  module HasPhoneNumber
    extend ActiveSupport::Concern

    included do
      validate :validate_phone_number
      before_save :format_phone_number
    end

    def validate_phone_number
      return if phone_number.blank?

      errors.add(:phone_number, :invalid) if PhoneNumberValidation.parsed_number(phone_number).blank?
    end

    def format_phone_number
      self.phone_number_formatted = PhoneNumberValidation.parsed_number(phone_number)&.e164
    end

    def phone_number_formatted
      # overrides getter to make sure value is synced with phone_number
      format_phone_number
      super
    end

    def humanized_phone_number
      Phonelib.parse(phone_number_formatted).national
    end

    def partially_hidden_phone_number
      humanized_phone_number&.gsub(" ", "")&.tap { |number| number[-8..-3] = "******" }
    end
  end
end
