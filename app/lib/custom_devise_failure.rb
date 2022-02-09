# frozen_string_literal: true

class CustomDeviseFailure < Devise::FailureApp
  # redirect to registration
  def route(scope)
    scope == :user ? :new_user_registration_url : super
  end

  def respond
    if http_auth?
      http_auth
    else
      redirect
    end
  end
end
