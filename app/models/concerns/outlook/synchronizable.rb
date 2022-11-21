module Outlook
  module Synchronizable
    extend ActiveSupport::Concern

    USER_AGENT = "RDVSolidarites"
    BASE_URL = "https://graph.microsoft.com/v1.0"

    included do
      after_commit :create_outlook_events, on: :create

      after_commit :update_outlook_events, on: :update

      around_destroy :destroy_outlook_events

      alias_attribute :exists_in_outlook?, :outlook_id?
    end

    def exists_in_outlook?
      !!outlook_id
    end

    def create_outlook_events
      agents.connected_to_outlook.each do |agent|
        Outlook::CreateEventJob.perform_now(self, agent)
      end
    end

    def update_outlook_events
      agents.connected_to_outlook.each do |agent|
        if cancelled?
          Outlook::DestroyEventJob.perform_later(self, agent)
          update(outlook_id: nil)
        else
          Outlook::UpdateEventJob.perform_later(self, agent)
        end
      end
    end

    def destroy_outlook_events
      agents.connected_to_outlook.each do |agent|
        Outlook::DestroyEventJob.perform_later(self, agent) if exists_in_outlook?
      end
    end

    # https://docs.microsoft.com/en-us/graph/use-the-api?view=graph-rest-1.0
    # method (string): The HTTP method to use for the API call.
    #                  Must be 'GET', 'POST', 'PATCH', or 'DELETE'
    # url (string): The URL to use for the API call. Must not contain
    #               the host. For example: '/api/v2.0/me/messages'
    # payload (hash): a JSON hash representing the API call's payload. Only used
    #                 for POST or PATCH.
    def make_api_call(agent, method, url, payload = {})
      headers = {
        "Authorization" => "Bearer #{agent.microsoft_graph_token}",
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "User-Agent" => USER_AGENT,
        "client-request-id" => SecureRandom.uuid,
        "return-client-request-id" => "true",
      }

      request_url = "#{BASE_URL}/#{url}"

      response = case method.upcase
                 when "POST"
                   Typhoeus.post(request_url, headers: headers, body: JSON.dump(payload))
                 when "PATCH"
                   Typhoeus.patch(request_url, headers: headers, body: JSON.dump(payload))
                 when "DELETE"
                   Typhoeus.delete(request_url, headers: headers)
                 end

      JSON.parse(response.body)
    end

    # payload (hash): a JSON hash representing the event entity
    # calendar_id (string): The Id of the calendar to create the event in.
    #                     If nil, event is created in the default calendar.
    def create_outlook_event(agent, payload, calendar_id = nil)
      agent.refresh_outlook_token

      request_url = if calendar_id.present?
                      "me/Calendars/#{calendar_id}/Events"
                    else
                      "me/Events"
                    end

      make_api_call(agent, "POST", request_url, payload)
    end

    # payload (hash): a JSON hash representing the updated event fields
    # id (string): The Id of the event to update.
    def update_outlook_event(agent, payload, id)
      agent.refresh_outlook_token

      make_api_call(agent, "PATCH", "me/Events/#{id}", payload)
    end

    # id (string): The Id of the event to delete.
    def delete_outlook_event(agent, id)
      agent.refresh_outlook_token

      make_api_call(agent, "DELETE", "me/Events/#{id}")
    end

    def outlook_payload(agent)
      {
        subject: object,
        body: {
          contentType: "HTML",
          content: event_description_for(agent)
        },
        start: {
          dateTime: starts_at.iso8601,
          timeZone: Time.zone_default.tzinfo.identifier
        },
        end: {
          dateTime: ends_at.iso8601,
          timeZone: Time.zone_default.tzinfo.identifier
        },
        location: {
          displayName: address_without_personal_information
        }
      }
    end
  end
end
