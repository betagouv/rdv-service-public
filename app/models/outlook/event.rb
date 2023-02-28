# frozen_string_literal: true

module Outlook
  class Event
    include ActiveModel::Model

    USER_AGENT = "RDVSolidarites"
    BASE_URL = "https://graph.microsoft.com/v1.0"

    attr_reader :agents_rdv, :outlook_id, :agent

    def initialize(outlook_id: nil, agents_rdv: nil, agent: nil)
      @agents_rdv = agents_rdv
      @outlook_id = @agents_rdv&.outlook_id || outlook_id
      @agent = @agents_rdv&.agent || agent
    end

    # @return [String] the outlook_id of the created event
    def create
      outlook_event = make_api_call("POST", "me/Events", payload)
      outlook_event["id"]
    end

    def update
      make_api_call("PATCH", "me/Events/#{outlook_id}", payload)
    end

    def destroy
      make_api_call("DELETE", "me/Events/#{outlook_id}")
    end

    private

    delegate :rdv, :id, :users, to: :agents_rdv, allow_nil: true
    delegate :microsoft_graph_token, :connected_to_outlook?, to: :agent, prefix: true
    delegate :object, :starts_at, :ends_at, :address_without_personal_information, to: :rdv

    # https://docs.microsoft.com/en-us/graph/use-the-api?view=graph-rest-1.0
    # method (string): The HTTP method to use for the API call.
    #                  Must be 'GET', 'POST', 'PATCH', or 'DELETE'
    # url (string): The URL to use for the API call. Must not contain
    #               the host. For example: '/api/v2.0/me/messages'
    # payload (hash): a JSON hash representing the API call's payload. Only used
    #                 for POST or PATCH.

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def make_api_call(method, url, event_payload = {})
      headers = {
        "Authorization" => "Bearer #{agent_microsoft_graph_token}",
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "User-Agent" => USER_AGENT,
        "client-request-id" => SecureRandom.uuid,
        "return-client-request-id" => "true",
      }

      request_url = "#{BASE_URL}/#{url}"

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
        if agent_connected_to_outlook? && response.response_code == 401 # token expired
          agent.refresh_outlook_token && make_api_call(method, url, event_payload)
        else
          raise "Outlook API error for AgentsRdv #{id || outlook_id}: #{body_response.dig('error', 'message')}"
        end
      end
      response.response_code == 204 ? "" : body_response
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    def payload
      {
        subject: object,
        body: {
          contentType: "HTML",
          content: event_description,
        },
        start: {
          dateTime: starts_at.iso8601,
          timeZone: Time.zone_default.tzinfo.identifier,
        },
        end: {
          dateTime: ends_at.iso8601,
          timeZone: Time.zone_default.tzinfo.identifier,
        },
        location: {
          displayName: address_without_personal_information,
        },
        attendees: [],
      }
    end

    def event_description
      url_helpers = Rails.application.routes.url_helpers

      show_link = url_helpers.admin_organisation_rdv_url(rdv.organisation, id, host: agent.dns_domain_name)
      edit_link = url_helpers.edit_admin_organisation_rdv_url(rdv.organisation, id, host: agent.dns_domain_name)

      participants_list = rdv.users.map do |user|
        "<li>#{user.full_name}</li>"
      end.join

      <<~HTML
        participants:
        <ul>#{participants_list}</ul>
        <br />

        plus d'infos sur <href a="#{show_link}">#{agent.domain_name}</href>:
        <br />

        Attention: ne modifiez pas cet évènement directement dans outlook, car il ne sera pas mis à jour sur #{agent.domain_name}.
        Pour modifier ce rendez-vous, allez sur <href a="#{edit_link}">#{agent.domain_name}</href>
      HTML
    end
  end
end
