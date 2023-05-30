# frozen_string_literal: true

Typhoeus.before do |request|
  filter_secrets_from_body = lambda do |body|
    body.to_s.gsub(InclusionConnect::IC_CLIENT_SECRET || "", "filtered")
  end

  crumb = Sentry::Breadcrumb.new(
    message: "HTTP request",
    data: {
      method: request.options[:method],
      url: request.url,
      headers: request.options[:headers],
      body: filter_secrets_from_body.call(request.encoded_body),
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
