module WelcomeHelper
  def root_path?
    root_path == request.path
  end

  def sign_up_agent_button
    link_to 'Je m\'inscris', new_agent_registration_path, class: 'btn btn-primary'
  end

  def sign_in_agent_button
    link_to 'Se connecter', new_agent_session_path, class: 'btn btn-outline-white'
  end

  def sign_in_user_button
    link_to 'Se connecter', new_user_session_path, class: 'btn btn-white'
  end
end
