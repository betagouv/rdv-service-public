class FaradaySentryBreadcrumbsMiddleware < Faraday::Middleware
  def call(request_env)
    add_request_breadcrumb(request_env)

    @app.call(request_env).on_complete do |response_env|
      add_response_breadcrumb(response_env)
    end
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
    add_timeout_breadcrumb(e)
    raise
  end

  private

  def add_request_breadcrumb(request_env)
    breadcrumb = {
      message: "HTTP request",
      data: {
        method: request_env.method,
        url: request_env.url,
        headers: request_env.request_headers,
        body: options[:scrub_request_body] ? "[SCRUBBED]" : request_env.body,
      },
    }
    Sentry.add_breadcrumb(Sentry::Breadcrumb.new(**breadcrumb))
  end

  def add_response_breadcrumb(response_env)
    breadcrumb = {
      message: "HTTP response",
      data: {
        status: response_env.status,
        headers: response_env.response_headers,
        body: response_env.response_body,
      },
    }
    Sentry.add_breadcrumb(Sentry::Breadcrumb.new(**breadcrumb))
  end

  def add_timeout_breadcrumb(exception)
    Sentry.add_breadcrumb Sentry::Breadcrumb.new(message: "HTTP timeout", data: { exception_message: exception.message })
  end
end
Faraday::Middleware.register_middleware(sentry_breadcrumbs: FaradaySentryBreadcrumbsMiddleware)
