# frozen_string_literal: true

class Rack::Attack
  throttle("requests by ip", limit: 20, period: 60) do |request|
    request.ip if request.path.include?('/api')
  end

  self.throttled_responder = lambda do |request|
    match_data = request.env['rack.attack.match_data']
    now = match_data[:epoch_time]

    headers = {
      'Content-Type' => 'application/json',
      'RateLimit-Limit' => match_data[:limit].to_s,
      'RateLimit-Remaining' => '0',
      'Retry-After' => (match_data[:period] - (now % match_data[:period])).to_s,
    }

    [429, headers, [{ errors: ["Limite d'appels API atteinte. Merci de patienter.\n"] }.to_json]]
  end
end
