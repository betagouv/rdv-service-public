class CaldavConfig < ApplicationRecord
  has_paper_trail

  encrypts :caldav_password, deterministic: true

  belongs_to :agent

  validates :caldav_calendar_color, css_hex_color: true, allow_blank: true

  # Passed to Http#timeout, see https://github.com/httprb/http/blob/v5.3.1/lib/http/chainable.rb#L85
  CALENDAV_CLIENT_HTTP_TIMEOUT = {
    connect: 2,
    read: 30,
    write: 30,
  }.freeze

  def caldav_client
    @caldav_client ||= Calendav::Client.new(caldav_credentials, timeout: CALENDAV_CLIENT_HTTP_TIMEOUT)
  end

  def caldav_credentials
    Calendav::Credentials::Standard.new(
      host: caldav_agenda_url,
      username: caldav_username,
      password: caldav_password,
      authentication: :basic_auth
    )
  end
end
