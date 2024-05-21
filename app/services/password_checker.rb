class PasswordChecker
  def initialize(password)
    @agent_for_validation = Agent.new(password: password) # ne sera pas persisté
    @agent_for_validation.validate
  end

  def too_weak?
    # Si l'agent se connecte par oauth, on ne fait pas de vérification sur le mot de passe
    return false if @agent_for_validation.password.blank?

    @agent_for_validation.errors[:password].any?
  end
end
