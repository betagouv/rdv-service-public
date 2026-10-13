# https://developers.brevo.com/reference/delete_smtp-blockedcontacts-email
class UnblockBrevoTransactionalContact
  def initialize(email)
    @email = email
  end

  def call
    if ENV["BREVO_API_KEY"].blank?
      Sentry.capture_message("BREVO_API_KEY is not set, cannot unblock Brevo transactional contact", level: :error) if Rails.env.production?
      return
    end

    response = Faraday.delete("https://api.brevo.com/v3/smtp/blockedContacts/#{CGI.escape(@email)}") do |req|
      req.headers["accept"] = "application/json"
      req.headers["api-key"] = ENV["BREVO_API_KEY"]
      req.options.timeout = 5
    end

    # On reçoit une 204 si le contact a été débloqué avec succès et une 404 si le contact n’était pas bloqué
    # Dans les deux cas, on considère que l’opération est un succès. Dans les autres cas, on logue l’erreur dans Sentry.
    unless response.status.in?([204, 404])
      Sentry.capture_message("Failed to unblock Brevo transactional contact", level: :error, extra: { email: @email, status: response.status, body: response.body })
    end
  # Le déblocage est une étape de confort avant l'envoi d'un email : une indisponibilité de Brevo
  # (timeout, erreur réseau, etc.) ne doit pas empêcher l'envoi, et donc par exemple bloquer la connexion par code.
  rescue StandardError => e
    Sentry.capture_exception(e, extra: { email: @email })
  end
end
