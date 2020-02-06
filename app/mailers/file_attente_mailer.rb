class FileAttenteMailer < ApplicationMailer
  def send_notification(rdv, user, creneau_starts_at)
    @rdv = rdv
    @creneau_starts_at = creneau_starts_at
    mail(to: user.email, subject: "Un créneau vient de se liberer !")
  end
end
