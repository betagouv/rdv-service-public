class FileAttenteMailer < ApplicationMailer
  def send_notification(user, rdv)
    @rdv = rdv
    mail(to: user.email, subject: "Un créneau vient de se liberer !")
  end
end
