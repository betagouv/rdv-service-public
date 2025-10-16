module Notifiers::AgentsFilter
  include DateHelper

  def self.agents_to_notify(rdv, agents)
    agents.select { |agent| should_notify_agent?(rdv, agent) }
  end

  def self.should_notify_agent?(rdv, agent)
    level = agent.rdv_notifications_level
    return true if level == "all"
    return false if level == "none"
    return false if author == agent
    return false if level == "soon" && !soon_date?(rdv.starts_at) && !soon_date?(rdv.attribute_before_last_save(:starts_at))

    true
  end
end
