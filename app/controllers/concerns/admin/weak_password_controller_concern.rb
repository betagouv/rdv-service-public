module Admin::WeakPasswordControllerConcern
  def reset_password_if_weak!
    return false unless password_too_weak?

    current_agent.password = Admin::WeakPasswordControllerConcern.generate_password
    current_agent.save!
    reset_password_token = current_agent.send(:set_reset_password_token)
    sign_out current_agent # required because this method is called after warden.authenticate!

    redirect_to edit_agent_password_path(reset_password_token:), flash: { error: weak_password_error_message }
    true
  end

  def self.generate_password
    "#{Devise.friendly_token}!3Aa".chars.shuffle.join
  end

  protected

  def weak_password_error_message
    <<~MESSAGE
      Pour des raisons de sécurité, nous vous demandons de changer votre mot de passe actuel qui présente des vulnérabilités.
      Merci de le modifier avant d'accéder à votre espace personnel.
    MESSAGE
  end

  def password_too_weak?
    Agent
      .new(password: params[:agent][:password])
      .tap(&:readonly!)
      .tap(&:validate)
      .errors[:password]
      .any?
  end
end
