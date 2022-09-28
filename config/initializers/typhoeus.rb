# frozen_string_literal: true

Typhoeus.before do |request|
  crumb = Sentry::Breadcrumb.new(
    message: "HTTP request",
    data: {
      method: request.options[:method],
      url: request.url,
      headers: request.options[:headers],
      body: request.encoded_body,
    }
  )
  Sentry.add_breadcrumb(crumb)
end

Typhoeus.on_complete do |response|
  crumb = Sentry::Breadcrumb.new(
    message: "HTTP response",
    data: {
      code: response.code,
      headers: response.headers,
      body: response.body,
    }
  )
  Sentry.add_breadcrumb(crumb)
end
