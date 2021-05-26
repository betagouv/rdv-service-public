# frozen_string_literal: true

class Users::FileAttenteMailerPreview < ActionMailer::Preview
  def new_creneau_available
    Users::FileAttenteMailer.new_creneau_available(Rdv.last, User.last)
  end
end
