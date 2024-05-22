module User::NotificableConcern
  extend ActiveSupport::Concern

  def notifiable_by_email?
    email_address.present? && notify_by_email?
  end

  def email_address
    email || contact_email
  end

  def notifiable_by_sms?
    phone_number_formatted.present? && phone_number_mobile? && notify_by_sms?
  end

  def phone_number_mobile?
    return false if phone_number_formatted.blank?

    PhoneNumberValidation.number_is_mobile?(phone_number)
  end
end
