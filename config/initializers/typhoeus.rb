DEFAULT_TYPHOEUS_TIMEOUT = 15
class Typhoeus::Errors::TimeoutError < Typhoeus::Errors::TyphoeusError; end

class Typhoeus::Request
  attr_accessor :scrub_from_sentry_breadcrumbs
end

#
# Typhoeus ne lève pas d'exception en cas de timeout, donc on fait
# en sorte de mettre un timeout par défaut et de lever l'exception.
#
# IMPORTANT : L'usage conventionnel est donc le suivant :
#   si aucun callback `on_failure` n'est défini dans le code de la
#   requête, c'est le `on_failure` ci-dessous qui sera exécuté.
#
Typhoeus.before do |request|
  request.options[:timeout] ||= DEFAULT_TYPHOEUS_TIMEOUT
  if request.on_failure.blank?
    request.on_failure do |response|
      if response.timed_out?
        raise Typhoeus::Errors::TimeoutError, "Timed out calling #{response.request.base_url}"
      end
    end
  end
  true # Petit piège :  si on retourne du falsy, la requête n'est pas exécutée du tout.
end

Typhoeus.before do |request|
  data = {
    method: request.options[:method],
    url: request.url,
    headers: request.options[:headers],
  }
  data[:body] =
    if request.scrub_from_sentry_breadcrumbs&.include?(:body)
      "*** scrubbed ***"
    else
      request.encoded_body.to_s # TODO: filtrer toutes les variables d'env ici ?
    end
  Sentry.add_breadcrumb Sentry::Breadcrumb.new(message: "HTTP request", data:)
end

Typhoeus.on_complete do |response|
  crumb = Sentry::Breadcrumb.new(
    message: "HTTP response",
    data: {
      code: response.code,
      headers: response.headers.to_h,
      body: response.body,
      return_code: response.return_code,
    }
  )
  Sentry.add_breadcrumb(crumb)
end
