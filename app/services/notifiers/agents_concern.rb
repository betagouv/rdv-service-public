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
    Notifiers::AgentsConcern.should_notify_agent?(rdv, agent, author)
  end

  def self.should_notify_agent?(rdv, agent, author)
    level = agent.rdv_notifications_level
    return true if level == "all"
    return false if level == "none"
    return false if author == agent
    return false if level == "soon" && !soon_date?(rdv.starts_at) && !soon_date?(rdv.attribute_before_last_save(:starts_at))

    true
  end

  # true if the passed date (or time) is today or tomorrow
  def self.soon_date?(date)
    return false unless date.respond_to?(:to_date)

    [Date.current, Date.current + 1].include?(date.to_date)
  end
end
