module Admin::WeakPasswordControllerConcern
  private

  def password_too_weak?(password)
    Agent.new(password:).tap(&:readonly!).tap(&:validate).errors[:password].any?
  end

  def reset_current_agent_password!
    resource.update_attribute(:encrypted_password, "") # rubocop:disable Rails/SkipsModelValidations
    reset_password_token = resource.send(:set_reset_password_token)

    redirect_to edit_agent_password_path(reset_password_token:), flash: { error: weak_password_error_message }
  end

  def weak_password_error_message
    <<~MESSAGE
      Pour des raisons de sécurité, nous vous demandons de changer votre mot de passe actuel qui présente des vulnérabilités.
      Merci de le modifier avant d'accéder à votre espace personnel.
    MESSAGE
  end
end
