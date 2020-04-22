class FileAttenteMailerPreview < ActionMailer::Preview
  def send_notification
    FileAttenteMailer.send_notification(Rdv.last, User.last)
  end
end
