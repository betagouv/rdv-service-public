class CaldavConfig < ApplicationRecord
  encrypts :caldav_password, deterministic: true

  belongs_to :agent

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
