# Fabrique de connexions Faraday avec les réglages communs à nos appels d'API externes :
# - un timeout par défaut (sans lui, Faraday attend indéfiniment)
# - des breadcrumbs Sentry pour la requête et la réponse
module HttpClient
  DEFAULT_TIMEOUT = 15

  # @param basic_auth [String, nil] "utilisateur:mot_de_passe"
  # @param form [Boolean] encode les bodies de type Hash en application/x-www-form-urlencoded
  # @param scrub_request_body [Boolean] masque le body de la requête dans les breadcrumbs Sentry
  def self.connection(url: nil, headers: {}, timeout: nil, basic_auth: nil, form: false, scrub_request_body: false)
    Faraday.new(url:, headers:, request: { timeout: timeout || DEFAULT_TIMEOUT }) do |builder|
      builder.request :url_encoded if form
      if basic_auth
        user, password = basic_auth.split(":", 2)
        builder.request :authorization, :basic, user, password.to_s
      end
      builder.use :sentry_breadcrumbs, scrub_request_body: scrub_request_body
    end
  end

  # Faraday lève ConnectionFailed (et non TimeoutError) pour un timeout à l'ouverture de la connexion.
  def self.timeout?(error)
    error.is_a?(Faraday::TimeoutError) ||
      (error.is_a?(Faraday::ConnectionFailed) && error.wrapped_exception.is_a?(Timeout::Error))
  end
end
