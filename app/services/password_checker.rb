class PasswordChecker
  def initialize(password)
    @agent_for_validation = Agent.new(password: password) # ne sera pas persisté
    @agent_for_validation.validate
  end

  def too_weak?
    @agent_for_validation.errors[:password].any?
  end
end
