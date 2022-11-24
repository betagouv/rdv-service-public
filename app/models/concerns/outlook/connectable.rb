# frozen_string_literal: true

module Outlook
  module Connectable
    extend ActiveSupport::Concern

    included do
      scope :connected_to_outlook, -> { where.not(microsoft_graph_token: nil) }

      alias_attribute :connected_to_outlook?, :microsoft_graph_token?
    end

    # https://docs.microsoft.com/en-us/graph/use-the-api?view=graph-rest-1.0

    REFRESH_TOKEN_URL = "https://login.microsoftonline.com/common/oauth2/v2.0/token"

    def refresh_outlook_token
      response = JSON.parse(refresh_token_query.response_body)
      if response["error"].present?
      Sentry.capture_message("Error refreshing Microsoft Graph Token for #{email}: #{response['error_description']}")
      elsif response["access_token"].present?
        update(microsoft_graph_token: response["access_token"])
      end
    end

    private

    def refresh_token_query
      Typhoeus.post(
        REFRESH_TOKEN_URL,
        headers: { "Content-Type" => "application/x-www-form-urlencoded" },
        body: {
          client_id: ENV["AZURE_APPLICATION_CLIENT_ID"],
          client_secret: ENV["AZURE_APPLICATION_CLIENT_SECRET"],
          refresh_token: refresh_microsoft_graph_token, grant_type: "refresh_token",
        }
      )
    end
  end
end
