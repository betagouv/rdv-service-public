# frozen_string_literal: true

module User::NotificableConcern
  extend ActiveSupport::Concern

  def notifiable_by_email?
    email.present? && notify_by_email?
  end

  def notifiable_by_sms?
    phone_number_formatted.present? && phone_number_mobile? && notify_by_sms?
  end

  def phone_number_mobile?
    return false if phone_number_formatted.blank?

    Phonelib.parse(phone_number_formatted).types.include?(:mobile)
  end
end
