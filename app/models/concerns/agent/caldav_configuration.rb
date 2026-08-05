module Agent::CaldavConfiguration
  extend ActiveSupport::Concern

  included do
    has_one :caldav_config, dependent: :destroy
  end

  delegate :caldav_agenda_url, :caldav_username, :caldav_password, :caldav_sync_token, :caldav_disconnect_started_at, :caldav_include_sensitive_data, to: :caldav_config, allow_nil: true

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
