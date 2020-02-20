class FileAttenteMailer < ApplicationMailer
  def send_notification(rdv, user)
    @rdv = rdv
    mail(to: user.email, subject: "Un créneau vient de se liberer !")
  end
end
