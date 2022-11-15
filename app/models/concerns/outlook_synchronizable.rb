module OutlookSynchronizable
  # https://docs.microsoft.com/en-us/graph/use-the-api?view=graph-rest-1.0

  USER_AGENT = "RDVSolidarites"
  BASE_URL = "https://graph.microsoft.com/v1.0"
  REFRESH_TOKEN_URL = "https://login.microsoftonline.com/common/oauth2/v2.0/token"

  # method (string): The HTTP method to use for the API call.
  #                  Must be 'GET', 'POST', 'PATCH', or 'DELETE'
  # url (string): The URL to use for the API call. Must not contain
  #               the host. For example: '/api/v2.0/me/messages'
  # params (hash) a Ruby hash containing any query parameters needed for the API call
  # payload (hash): a JSON hash representing the API call's payload. Only used
  #                 for POST or PATCH.
  def make_api_call(method, url, params = nil, payload = {})
    headers = {
      "Authorization" => "Bearer #{microsoft_graph_token}",
      "Content-Type" => "application/json",
      "Accept" => "application/json",
      "User-Agent" => USER_AGENT,
      "client-request-id" => SecureRandom.uuid,
      "return-client-request-id" => "true",
    }

    request_url = "#{BASE_URL}/#{url}"

    response = case method.upcase
               when "GET"
                 Typhoeus.get(request_url, headers: headers, params: params)
               when "POST"
                 Typhoeus.post(request_url, headers: headers, params: params,
                                            body: JSON.dump(payload))
               when "PATCH"
                 Typhoeus.patch(request_url, headers: headers, params: params,
                                             body: JSON.dump(payload))
               when "DELETE"
                 Typhoeus.delete(request_url, headers: headers, params: params)
               end

    JSON.parse(response.body)
  end

  def refresh_outlook_token
    response = JSON.parse(refresh_token_query.response_body)
    if response["error"].present?
      Rails.logger.error("Could not get new token for #{agent.email}: #{response['error_description']}")
    elsif response["access_token"].present?
      update(microsoft_graph_token: response["access_token"])
    end
  end

  #----- Begin Calendar API -----#

  # view_size (int): maximum number of results
  # page (int): What page to fetch (multiple of view size)
  # fields (array): An array of field names to include in results
  # sort (hash): { sort_on => field_to_sort_on, sort_order => 'ASC' | 'DESC' }
  def get_calendars(view_size = 20, page = 1, fields = nil, sort = nil)
    refresh_outlook_token

    request_params = {
      "$top" => view_size,
      "$skip" => (page - 1) * view_size,
    }
    request_params["$select"] = fields.join(",") unless fields.nil?
    request_params["$orderby"] = "#{sort[:sort_field]} #{sort[:sort_order]}" unless sort.nil?

    make_api_call("GET", "me/calendars", request_params)
  end

  # payload (hash): a JSON hash representing the calendar entity
  #                 {
  #                   "Name": "Social"
  #                 }
  # calendar_group_id (string): The Id of the calendar group to create the calendar in.
  #                     If nil, calendar is created in the default calendar group.
  def create_calendar(payload, calendar_group_id = nil)
    refresh_outlook_token

    request_url = if calendar_group_id.present?
                    "me/CalendarGroups/#{calendar_group_id}"
                  else
                    "me/calendars"
                  end

    make_api_call("POST", request_url, nil, payload)
  end

  # payload (hash): a JSON hash representing the event entity
  # folder_id (string): The Id of the calendar folder to create the event in.
  #                     If nil, event is created in the default calendar folder.
  def create_event(payload, folder_id = nil)
    refresh_outlook_token

    request_url = if folder_id.present?
                    "me/Calendars/#{folder_id}"
                  else
                    "me/Events"
                  end

    make_api_call("POST", request_url, nil, payload)
  end

  # payload (hash): a JSON hash representing the updated event fields
  # id (string): The Id of the event to update.
  def update_event(payload, id)
    refresh_outlook_token

    make_api_call("PATCH", "me/Events/#{id}", nil, payload)
  end

  # id (string): The Id of the event to delete.
  def delete_event(id)
    refresh_outlook_token

    make_api_call("DELETE", "me/Events/#{id}")
  end

  #----- End Calendar API -----#

  private

  def refresh_token_query
    Typhoeus.post(
      REFRESH_TOKEN_URL,
      headers: { "Content-Type" => "application/x-www-form-urlencoded" },
      body: {
        client_id: ENV.fetch("AZURE_APPLICATION_CLIENT_ID", nil),
        client_secret: ENV.fetch("AZURE_APPLICATION_CLIENT_SECRET", nil),
        refresh_token: refresh_microsoft_graph_token, grant_type: "refresh_token",
      }
    )
  end
end
