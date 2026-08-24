class Users::FileAttenteMailerPreview < ActionMailer::Preview
  def new_creneau_available
    rdv = Rdv.last
    user = User.last
    Users::FileAttenteMailer.with(rdv:, user:).new_creneau_available
  end
end
