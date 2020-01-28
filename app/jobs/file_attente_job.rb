class FileAttenteJob < ApplicationJob
  def perform(user, rdv)
    TwilioSenderJob.perform_later(:file_attente, rdv, user) if user.formated_phone
    FileAttenteMailer.send_notification(rdv, user) if user.email
  end
end
