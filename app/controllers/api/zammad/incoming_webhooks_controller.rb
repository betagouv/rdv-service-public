require "byebug"

class Api::Zammad::IncomingWebhooksController < ActionController::Base # rubocop:disable Rails/ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    raise "missing ZAMMAD_WEBHOOKS_TOKEN environment variable" if ENV["ZAMMAD_WEBHOOKS_TOKEN"].blank?

    if request.headers["HTTP_X_HUB_SIGNATURE"].blank?
      render status: :bad_request, plain: "Missing signature"
      return
    end

    raw_body = request.body.read
    signature = "sha1=#{OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ENV['ZAMMAD_WEBHOOKS_TOKEN'], raw_body)}"

    if Rack::Utils.secure_compare(signature, request.headers["HTTP_X_HUB_SIGNATURE"])
      IncomingZammadWebhookJob.perform_later(JSON.parse(raw_body))
      render status: :ok, plain: "OK"
    else
      render status: :forbidden, plain: "Invalid signature"
    end
  end
end
