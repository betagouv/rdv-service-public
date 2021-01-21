class RedirectToRegistration < Devise::FailureApp
  def route(scope)
    scope == :user ? :new_user_registration_url : super
  end
end
