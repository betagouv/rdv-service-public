# frozen_string_literal: true

DEFAULT_TYPHOEUS_TIMEOUT = 15
class Typhoeus::Errors::TimeoutError < Typhoeus::Errors::TyphoeusError; end

# Typhoeus ne lève pas d'exception en cas de timeout, donc on fait
# en sorte de mettre un timeout par défaut et de lever l'exception.
Typhoeus.before do |request|
  request.options[:timeout] ||= DEFAULT_TYPHOEUS_TIMEOUT
  # Les timeouts sont parfois gérés de façon adaptée au niveau de l'appel.
  # Nous ajoutons ce callback `on_failure` pour avoir une levée d'exception par défaut.
  if request.on_failure.blank?
    request.on_failure do |response|
      if response.timed_out?
        raise Typhoeus::Errors::TimeoutError, "Timed out calling #{response.request.url}"
      end
    end
  end
  true # Si le block de callback retourne une valeur falsy, la requête est annulée.
end

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
