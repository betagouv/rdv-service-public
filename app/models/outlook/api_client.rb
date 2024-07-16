module Outlook
  class ApiClient
    class ApiError < StandardError; end
    class NotFoundError < ApiError; end
    class AlreadyExistsError < ApiError; end
    class RefreshTokenError < ApiError; end

    def initialize(agent)
      @agent = agent
    end

    # @return [String] the outlook_id of the created event
    def create_event!(payload)
      outlook_event = call_events_api("POST", "me/Events", payload)
      outlook_event["id"]
    rescue AlreadyExistsError => e
      Rails.logger.error("Outlook error while creating event: #{e.message}")
    end

    def update_event!(outlook_event_id, payload)
      call_events_api("PATCH", "me/Events/#{outlook_event_id}", payload)
    end

    def delete_event!(outlook_event_id)
      call_events_api("DELETE", "me/Events/#{outlook_event_id}")
    rescue NotFoundError => e
      Rails.logger.error("Outlook error while deleting event: #{e.message}")
    end

    private

    USER_AGENT = "RDVSolidarites".freeze
    BASE_URL = "https://graph.microsoft.com/v1.0".freeze

    # https://docs.microsoft.com/en-us/graph/use-the-api?view=graph-rest-1.0
    # method (string): The HTTP method to use for the API call.
    #                  Must be 'GET', 'POST', 'PATCH', or 'DELETE'
    # path (string): The path to use for the API call. Must not contain a forward slash. For example: 'api/v2.0/me/messages'
    # payload (hash): a JSON hash representing the API call's payload. Only used
    #                 for POST or PATCH.

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def call_events_api(method, path, event_payload = {})
      headers = {
        "Authorization" => "Bearer #{@agent.microsoft_graph_token}",
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "User-Agent" => USER_AGENT,
        "client-request-id" => SecureRandom.uuid,
        "return-client-request-id" => "true",
      }

      request_url = "#{BASE_URL}/#{path}"

      response = case method.upcase
                 when "POST"
                   Typhoeus.post(request_url, headers: headers, body: JSON.dump(event_payload))
                 when "PATCH"
                   Typhoeus.patch(request_url, headers: headers, body: JSON.dump(event_payload))
                 when "DELETE"
                   Typhoeus.delete(request_url, headers: headers)
                 end

      body_response = response.body == "" ? {} : JSON.parse(response.body)
      if body_response["error"].present?
        if @agent.connected_to_outlook? && response.response_code == 401 # token expired
          refresh_outlook_token && call_events_api(method, path, event_payload)
        else
          raise_exception(error_code: body_response["error"]["code"], error_message: body_response["error"]["message"])
        end
      end
      response.response_code == 204 ? "" : body_response
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    def refresh_outlook_token
      refresh_token_query =
        Typhoeus.post(
          # voir https://docs.microsoft.com/en-us/graph/use-the-api?view=graph-rest-1.0
          "https://login.microsoftonline.com/common/oauth2/v2.0/token",
          headers: { "Content-Type" => "application/x-www-form-urlencoded" },
          body: {
            client_id: ENV.fetch("AZURE_APPLICATION_CLIENT_ID", nil),
            client_secret: ENV.fetch("AZURE_APPLICATION_CLIENT_SECRET", nil),
            refresh_token: @agent.refresh_microsoft_graph_token, grant_type: "refresh_token",
          }
        )
      refresh_token_response = JSON.parse(refresh_token_query.response_body)

      if refresh_token_response["error"].present?
        raise RefreshTokenError, refresh_token_response["error"]
      elsif refresh_token_response["access_token"].present?
        @agent.update!(microsoft_graph_token: refresh_token_response["access_token"])
      end
    end

    def raise_exception(error_code:, error_message:)
      exception_class = case error_code
                        when "ErrorItemNotFound"
                          NotFoundError
                        when "ErrorDuplicateTransactionId"
                          AlreadyExistsError
                        else
                          ApiError
                        end
      raise exception_class, error_message
    end
  end
end
