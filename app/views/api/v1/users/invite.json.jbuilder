# frozen_string_literal: true
if @user.email.present?
  json.invitation_url accept_user_invitation_url(invitation_token: @user.raw_invitation_token)
else
  json.invitation_token @user.raw_invitation_token
end
