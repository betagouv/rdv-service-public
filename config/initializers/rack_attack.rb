class Rack::Attack
  throttle("API throttling by IP", limit: Rails.env.test? ? 2 : 20, period: 60) do |request|
    if request.path.match(%r{api/v1/rdvs}) && request.get?
      "#{request.ip}-api-rdvs-org-#{params[:organisation_id]}"
    end
  end

  # cf https://github.com/rack/rack-attack/tree/6-stable?tab=readme-ov-file#ratelimit-headers-for-well-behaved-clients
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = match_data[:epoch_time]

    headers = {
      "Content-Type" => "application/json",
      "RateLimit-Limit" => match_data[:limit].to_s,
      "RateLimit-Remaining" => "0",
      "Retry-After" => (match_data[:period] - (now % match_data[:period])).to_s,
    }

    [429, headers, [{ errors: ["Limite d'appels API atteinte. Merci de patienter."] }.to_json]]
  end
end
