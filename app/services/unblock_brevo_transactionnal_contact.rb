# https://developers.brevo.com/reference/delete_smtp-blockedcontacts-email
class UnblockBrevoTransactionnalContact
  def initialize(email)
    @email = email
  end

  def call
    response = Faraday.delete("https://api.brevo.com/v3/smtp/blockedContacts/#{CGI.escape(@email)}") do |req|
      req.headers["accept"] = "application/json"
      req.headers["api-key"] = ENV["BREVO_API_KEY"]
    end

    unless response.status.in?([204])
      Sentry.capture_message("Failed to unblock Brevo transactional contact", level: :error, extra: { email: @email, status: response.status, body: response.body })
    end
  end
end
