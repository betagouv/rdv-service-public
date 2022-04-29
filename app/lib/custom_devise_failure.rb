# frozen_string_literal: true

class CustomDeviseFailure < Devise::FailureApp
  # redirection
  def route(scope)
    scope == :user ? :new_user_session_url : super
  end

  # https://github.com/heartcombo/devise/wiki/How-To:-Redirect-to-a-specific-page-when-the-user-can-not-be-authenticated
  def redirect_url
    return accept_user_invitation_path(invitation_token: session[:invitation_token]) \
      if session[:invitation_token].present?

    super
  end

  def respond
    if http_auth?
      http_auth
    else
      redirect
    end
  end
end
