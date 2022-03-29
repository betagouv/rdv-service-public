# frozen_string_literal: true

class Users::FileAttenteMailer < ApplicationMailer
  def new_creneau_available(rdv, user, token)
    @rdv = rdv
    @token = token
    mail(to: user.email, subject: "Un créneau vient de se liberer !")
  end
end
