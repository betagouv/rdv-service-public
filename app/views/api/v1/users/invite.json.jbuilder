p @user
# if @user.email.present?
#   json.set! invitation_url: accept_user_invitation_url(invitation_token: @user.raw_invitation_token)
# else
#   json.set! invitation_token: @user.raw_invitation_token
# end
