class Rack::Attack
  throttle("formulaire de demande de support - throttling par IP", limit: Rails.env.test? ? 2 : 10, period: 60) do |request|
    if request.path.match(%r{aide/demande_support}) && request.post?
      request.ip
    end
  end
end
