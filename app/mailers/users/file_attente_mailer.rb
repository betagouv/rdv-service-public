# frozen_string_literal: true

class Users::FileAttenteMailer < ApplicationMailer
  def new_creneau_available(rdv, user)
    @rdv = rdv
    mail(to: user.email, subject: "Un créneau vient de se liberer !")
  end
end
