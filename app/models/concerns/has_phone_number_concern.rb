module HasPhoneNumberConcern
  extend ActiveSupport::Concern

  included do
    validates :phone_number, phone: { allow_blank: true }
    before_save :format_phone_number
  end

  def format_phone_number
    self.phone_number_formatted = (
      phone_number.present? &&
      Phonelib.valid?(phone_number) &&
      Phonelib.parse(phone_number).e164
    ) || nil
  end

  def phone_number_formatted
    # overrides getter to make sure value is synced with phone_number
    format_phone_number
    super
  end
end
