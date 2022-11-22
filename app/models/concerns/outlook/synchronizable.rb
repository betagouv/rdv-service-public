module Outlook
  module Synchronizable
    extend ActiveSupport::Concern

    USER_AGENT = "RDVSolidarites"
    BASE_URL = "https://graph.microsoft.com/v1.0"

    included do
      attr_accessor :skip_outlook_update

      after_commit :reflect_create_in_outlook, on: :create

      after_commit :reflect_update_in_outlook, on: :update, unless: :skip_outlook_update

      around_destroy :reflect_destroy_in_outlook

      alias_attribute :exists_in_outlook?, :outlook_id?

      delegate :connected_to_outlook?, to: :agent, prefix: true
    end

    # payload (hash): a JSON hash representing the event entity
    # calendar_id (string): The Id of the calendar to create the event in.
    #                     If nil, event is created in the default calendar.
    def create_outlook_event(calendar_id = nil)
      agent.refresh_outlook_token

      request_url = if calendar_id.present?
                      "me/Calendars/#{calendar_id}/Events"
                    else
                      "me/Events"
                    end

      make_api_call(agent, "POST", request_url, outlook_payload)
    end

    # payload (hash): a JSON hash representing the updated event fields
    # id (string): The Id of the event to update.
    def update_outlook_event
      agent.refresh_outlook_token

      make_api_call(agent, "PATCH", "me/Events/#{outlook_id}", outlook_payload)
    end

    # id (string): The Id of the event to destroy.
    def destroy_outlook_event
      agent.refresh_outlook_token

      make_api_call(agent, "DELETE", "me/Events/#{outlook_id}")
    end

    def reflect_create_in_outlook
      return unless agent_connected_to_outlook? && !exists_in_outlook?

      Outlook::CreateEventJob.perform_later(self)
    end

    def reflect_update_in_outlook
      if cancelled? || soft_deleted?
        reflect_destroy_in_outlook
      elsif exists_in_outlook?
        Outlook::UpdateEventJob.perform_later(self) if agent_connected_to_outlook?
      else
        reflect_create_in_outlook
      end
    end

    def reflect_destroy_in_outlook
      return unless agent_connected_to_outlook? && exists_in_outlook?

      Outlook::DestroyEventJob.perform_later(self)
    end

    private

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

    def outlook_payload
      {
        subject: rdv.object,
        body: {
          contentType: "HTML",
          content: rdv.event_description_for(agent)
        },
        start: {
          dateTime: rdv.starts_at.iso8601,
          timeZone: Time.zone_default.tzinfo.identifier
        },
        end: {
          dateTime: rdv.ends_at.iso8601,
          timeZone: Time.zone_default.tzinfo.identifier
        },
        location: {
          displayName: rdv.address_without_personal_information
        }
      }
    end
  end
end
