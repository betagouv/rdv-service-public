module User::NotificableConcern
  extend ActiveSupport::Concern

  def notifiable_by_email?
    valid_email? && notify_by_email? && !soft_deleted?
  end

  def valid_email?
    email.present? || notification_email.present?
  end

  def preferred_email
    email.presence || notification_email.presence
  end

  def notifiable_by_sms?
    phone_number_formatted.present? && phone_number_mobile? && notify_by_sms? && !soft_deleted?
  end

  def phone_number_mobile?
    return false if phone_number_formatted.blank?

    PhoneNumberValidation.number_is_mobile?(phone_number)
  end
end
