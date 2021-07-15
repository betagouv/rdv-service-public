# frozen_string_literal: true

json.invitation_url accept_user_invitation_url(invitation_token: @user.raw_invitation_token)
json.invitation_token @user.raw_invitation_token
