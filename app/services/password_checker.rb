class PasswordChecker
  def initialize(password)
    @agent_for_validation = Agent.new(password: password) # ne sera pas persisté
    @agent_for_validation.validate
  end

  def too_weak?
    @agent_for_validation.errors[:password].any?
  end

  def error_message(app_name)
    <<~MESSAGE
      <div class="fa fa-exclamation-triangle mr-1" />
      Votre mot de passe est trop faible, vous devez le mettre à jour pour continuer d'utiliser #{app_name}.
      <a href="#{Rails.application.routes.url_helpers.edit_agent_mot_de_passes_path}">Changer de mot de passe</a>
    MESSAGE
  end
end
