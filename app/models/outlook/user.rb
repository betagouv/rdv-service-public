# frozen_string_literal: true

module Outlook
  class User
    include ActiveModel::Model

    # https://docs.microsoft.com/en-us/graph/use-the-api?view=graph-rest-1.0
    REFRESH_TOKEN_URL = "https://login.microsoftonline.com/common/oauth2/v2.0/token"

    attr_accessor :agent

    def refresh_token
      refresh_token_query =
        Typhoeus.post(
          REFRESH_TOKEN_URL,
          headers: { "Content-Type" => "application/x-www-form-urlencoded" },
          body: {
            client_id: ENV.fetch("AZURE_APPLICATION_CLIENT_ID", nil),
            client_secret: ENV.fetch("AZURE_APPLICATION_CLIENT_SECRET", nil),
            refresh_token: agent.refresh_microsoft_graph_token, grant_type: "refresh_token",
          }
        )
      JSON.parse(refresh_token_query.response_body)
    end
  end
end
