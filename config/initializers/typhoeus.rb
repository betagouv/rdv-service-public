DEFAULT_TYPHOEUS_TIMEOUT = 15
class Typhoeus::Errors::TimeoutError < Typhoeus::Errors::TyphoeusError; end

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
      headers: response.headers.to_h,
      body: response.body,
      return_code: response.return_code,
    }
  )
  Sentry.add_breadcrumb(crumb)
end
