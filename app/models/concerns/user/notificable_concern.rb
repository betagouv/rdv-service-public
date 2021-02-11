module User::NotificableConcern
  extend ActiveSupport::Concern

  def notifiable_by_email?
    email.present? && notify_by_email?
  end

  def notifiable_by_sms?
    phone_number_formatted.present? && notify_by_sms?
  end
end
