# frozen_string_literal: true

class Users::FileAttenteMailerPreview < ActionMailer::Preview
  def new_creneau_available
    Users::FileAttenteMailer.with(rdv: Rdv.last, user: User.last).new_creneau_available
  end
end
