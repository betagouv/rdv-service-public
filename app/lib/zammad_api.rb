# frozen_string_literal: true

module ZammadApi
  class HttpError < StandardError; end

  class RequestError < StandardError; end

  class << self
    def create_ticket(email, ticket_title, ticket_body)
      response = Typhoeus::Request.new(
        "https://rdv-solidarites.zammad.com/api/v1/tickets",
        method: :post,
        body: JSON.dump(
          title: ticket_title,
          group: "Users",
          customer_id: "guess:#{email}",
          article: { body: ticket_body }
        ),
        headers: {
          "Content-Type": "application/json",
          Authorization: "Token token=#{ENV['ZAMMAD_API_TOKEN']}"
        }
      ).run
      if response.success?
        [true, {}]
      elsif response.timed_out? || response.code.zero?
        Sentry.capture_exception(HttpError.new(response.code))
        [false, { errors: ["HTTP request failed"] }]
      else
        parsed_response = JSON.parse(response.body)
        Sentry.capture_exception(RequestError.new(parsed_response["error_human"]))
        [false, { errors: [parsed_response["error_human"]] }]
      end
    end
  end
end
