require "faraday"
require "uri"

class MattermostApiClient
  def self.connection
    @connection ||= Faraday.new(
      url: "#{webhook_uri.scheme}://#{webhook_uri.host}:#{webhook_uri.port}"
    ) do |builder|
      builder.request :json
      builder.response :json
      builder.response :raise_error # raise an error on 4xx and 5xx responses
    end
  end

  def self.send_message(channel:, text:, username: nil, icon_url: nil)
    connection.post(
      webhook_uri.path,
      { channel:, text:, username:, icon_url: }.to_json
    )
  end

  def self.webhook_uri
    @webhook_uri ||= URI.parse(ENV["MATTERMOST_WEBHOOK_URL"])
  end
end
