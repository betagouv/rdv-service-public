module Agent::CaldavConfiguration
  extend ActiveSupport::Concern

  def caldav_configured?
    caldav_agenda_url.present? || caldav_username.present? || caldav_agent_password.present?
  end
end
