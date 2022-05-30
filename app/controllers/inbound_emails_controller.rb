# frozen_string_literal: true

# rubocop:disable Rails/ApplicationController
class InboundEmailsController < ActionController::Base
  skip_before_action :verify_authenticity_token

  before_action :authenticate_sendinblue

  def sendinblue
    payload = request.params["items"].first
    TransferEmailReplyJob.perform_later(payload)
  end

  private

  def authenticate_sendinblue
    return if ActiveSupport::SecurityUtils.secure_compare(ENV["SENDINBLUE_INBOUND_PASSWORD"], params[:password])

    Sentry.capture_message("Sendinblue inbound controller was called without valid password")
    head :unauthorized
  end
end
# rubocop:enable Rails/ApplicationController
