class AmiClient
  def connection
    Faraday.new(
      url: ENV.fetch("AMI_URL"),
      headers: {
        "Authorization" => "Basic #{auth}",
        "Content-Type" => "application/json",
      }
    ) do |builder|
      builder.request :json
      builder.response :json
      builder.use :sentry_breadcrumbs
    end
  end

  private

  def auth
    Base64.strict_encode64("#{ENV['AMI_PARTNER_ID']}:#{ENV['AMI_PARTNER_SECRET']}")
  end
end
