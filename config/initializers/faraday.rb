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
        body: scrub_request_body?(request_env) ? "[SCRUBBED]" : request_env.body,
      },
    }
    Sentry.add_breadcrumb(Sentry::Breadcrumb.new(**breadcrumb))
  end

  # Peut être activé sur la connexion (`builder.use :sentry_breadcrumbs, scrub_request_body: true`)
  # ou sur une requête (`req.options.context = { scrub_request_body: true }`)
  def scrub_request_body?(request_env)
    options[:scrub_request_body] || request_env.request.context&.dig(:scrub_request_body)
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

# L'adapter net_http lève ConnectionFailed (et non TimeoutError) pour un timeout à l'ouverture de la connexion.
# On le normalise pour pouvoir rescuer uniquement Faraday::TimeoutError.
class FaradayConnectTimeoutMiddleware < Faraday::Middleware
  def call(env)
    @app.call(env)
  rescue Faraday::ConnectionFailed => e
    if e.wrapped_exception.is_a?(Timeout::Error)
      raise Faraday::TimeoutError, e.wrapped_exception, cause: e.wrapped_exception
    end

    raise
  end
end
Faraday::Middleware.register_middleware(connect_timeout: FaradayConnectTimeoutMiddleware)

# Sans timeout, Faraday attend indéfiniment. Cette valeur s'applique à toutes les connexions,
# elle peut être surchargée pour une requête avec `req.options.timeout = 5`.
Faraday.default_connection_options = { request: { timeout: 15 } }

# Connexion utilisée par Faraday.get, Faraday.post, etc.
Faraday.default_connection = Faraday.new do |builder|
  builder.request :url_encoded
  builder.use :sentry_breadcrumbs
  builder.use :connect_timeout
end
