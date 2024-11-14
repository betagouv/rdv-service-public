# cf /docs/interconnexions/brevo.md

# rubocop:disable Rails/ApplicationController
class InboundEmailsController < ActionController::Base
  skip_before_action :verify_authenticity_token

  before_action :authenticate_brevo

  def brevo
    payload = request.params["items"].first
    TransferEmailReplyJob.perform_later(payload)
  end

  private

  def authenticate_brevo
    return if ActiveSupport::SecurityUtils.secure_compare(ENV["BREVO_INBOUND_PASSWORD"], params[:password])

    Sentry.capture_message("Brevo inbound controller was called without valid password", fingerprint: ["brevo_inbound_pw_invalid"])
    head :unauthorized
  end
end
# rubocop:enable Rails/ApplicationController
