module Notifiers::AgentsConcern
  extend ActiveSupport::Concern

  def notify_agents
    agents_to_notify.each { notify_agent(_1) }
  end

  def notify_agent(_agent)
    # override this method in the including class
  end

  def agents_to_notify
    rdv.agents.select { should_notify_agent?(_1) }
  end

  def should_notify_agent?(agent)
    level = agent.rdv_notifications_level
    return true if level == "all"
    return false if level == "none"
    return false if author == agent
    return false if level == "soon" && !soon_date?(rdv.starts_at) && !soon_date?(rdv.attribute_before_last_save(:starts_at))

    true
  end
end
