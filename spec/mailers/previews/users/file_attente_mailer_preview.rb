class Users::FileAttenteMailerPreview < ActionMailer::Preview
  def new_creneau_available
    participation = Participation.last
    rdv = participation.rdv
    user = participation.user
    participation.set_restricted_authentication_token_if_missing_and_save
    token = participation.restricted_auth_token
    Users::FileAttenteMailer.with(rdv: rdv, user: user, token: token).new_creneau_available
  end
end
