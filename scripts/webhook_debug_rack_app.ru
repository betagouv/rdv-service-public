# rackup scripts/webhook_debug_rack_app.ru
# ngrok http 9292

require "openssl"
require "byebug"

class WebhookDebugRackApp
  def call(env)
    req = Rack::Request.new(env)
    data = req.body.read
    secret = "XA6YxLZTX8j1xnxk" # this is the shared secret we communicate with the Agents
    computed_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, data)
    received_signature = env["HTTP_X_LAPIN_SIGNATURE"]
    puts "computed_signature : #{computed_signature}"
    puts "received_signature : #{received_signature}"
    [200, { "Content-Type" => "text/html" }, ["Hello World!"]]
  end
end

run WebhookDebugRackApp.new
