class Rack::Attack
  class ThrottleError < StandardError; end

  throttle("formulaire de demande de support - throttling par IP", limit: Rails.env.test? ? 2 : 10, period: 1.minute) do |request|
    if request.path.match(%r{aide/demande_support}) && request.post?
      request.ip
    end
  end

  throttle("saisie de code de connexion usager - throttling par email", limit: Rails.env.test? ? 2 : 60, period: 10.minutes) do |request|
    if request.path.match(%r{users/sessions_by_code}) && request.post? && request.params.dig("login_code", "email").present?
      request.params.dig("login_code", "email")
    end
  end

  throttle("saisie de code de connexion agent - throttling par email", limit: Rails.env.test? ? 2 : 60, period: 10.minutes) do |request|
    if request.path.match(%r{agents/sessions_by_code}) && request.post? && request.params.dig("login_code", "email").present?
      request.params.dig("login_code", "email")
    end
  end

  throttle("connexion via token d'auth restreinte - throttling par IP", limit: Rails.env.test? ? 2 : 10, period: 1.minute) do |request|
    next unless request.get?

    request.ip if request.path.start_with?("/r/") ||
                  request.path.start_with?("/users/file_attente/unsubscribe/") ||
                  (request.path == "/prdv" && request.params["tkn"].present?) ||
                  (request.path == "/prendre_rdv" && request.params["invitation_token"].present?) ||
                  (request.path.match?(%r{\A/users/rdvs/[^/]+(/creneaux)?\z}) && request.params["invitation_token"].present?)
  end

  Rack::Attack.throttled_responder = lambda do |request|
    exception = ThrottleError.new(request.env["rack.attack.matched"])
    Sentry.set_context("rack_attack_match_data", request.env["rack.attack.match_data"])
    Sentry.capture_exception(exception, level: :warning)

    [302, { "Location" => "/500.html" }, []]
  end
end
