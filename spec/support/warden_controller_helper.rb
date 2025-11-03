module WardenControllerHelper
  def current_agent_id
    session["warden.user.agent.key"]&.first&.sole
  end
end
