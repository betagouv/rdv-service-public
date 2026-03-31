class Users::FileAttenteMailerPreview < ActionMailer::Preview
  def new_creneau_available
    rdv = Rdv.last
    user = User.last
    token = rdv.participations.find_by(user: user)&.restricted_auth_token
    Users::FileAttenteMailer.with(rdv: rdv, user: user, token: token).new_creneau_available
  end
end
