class CaldavConfig < ApplicationRecord
  encrypts :caldav_password, deterministic: true

  belongs_to :agent

  validates :caldav_calendar_color, css_hex_color: true, allow_blank: true

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
