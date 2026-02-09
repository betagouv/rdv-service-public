class HttpGemSentryFeature < HTTP::Feature
  def wrap_request(request)
    @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    headers = request.headers.to_h
    headers["Authorization"] = "[FILTERED]" if headers["Authorization"]

    request_breadcrumb = {
      type: "http",
      category: "Requête HTTP (http.rb)",
      data: {
        method: request.verb,
        url: request.uri.to_s,
        headers:,
      },
    }
    Sentry.add_breadcrumb(Sentry::Breadcrumb.new(**request_breadcrumb))

    request
  end

  def wrap_response(response)
    @end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    duration_ms = ((@end_time - @start_time) * 1000).round

    headers = response.headers.to_h
    headers["Set-Cookie"] = "[FILTERED]" if headers["Set-Cookie"]

    response_breadcrumb = {
      type: "http",
      category: "Réponse HTTP (http.rb)",
      data: {
        status_code: response.status,
        duration_ms:,
        headers:,
        body: response.body.to_s,
      },
    }
    Sentry.add_breadcrumb(Sentry::Breadcrumb.new(**response_breadcrumb))

    response
  end

  # Cette méthode est appelée en cas d'erreur de réseau (timeout ou autre), mais pas pour des erreurs HTTP 400-500.
  def on_error(request, error)
    error_breadcrumb = {
      type: "http",
      category: "Erreur HTTP (http.rb)",
      message: error.detailed_message,
      data: {
        method: request.verb,
        url: request.uri.to_s,
      },
    }
    Sentry.add_breadcrumb(Sentry::Breadcrumb.new(**error_breadcrumb))
  end
end

HTTP::Options.register_feature(:sentry, HttpGemSentryFeature)
HTTP.default_options = { features: [:sentry] }
