module Agent::CaldavConfiguration
  extend ActiveSupport::Concern

  def caldav_configured?
    caldav_agenda_url.present? || caldav_username.present? || caldav_password.present?
  end

  def caldav_client
    @caldav_client ||= Calendav::Client.new(
      Calendav::Credentials::Standard.new(
        host: caldav_agenda_url,
        username: caldav_username,
        password: caldav_password,
        authentication: :basic_auth
      )
    )
  end
end
