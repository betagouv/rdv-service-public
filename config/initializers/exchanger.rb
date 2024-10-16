Exchanger.configure do |config|
  config.endpoint = "https://mail.cd08.fr/ews"
  config.username = ENV["EXCHANGE_CLIENT_USERNAME"]
  config.password = ENV["EXCHANGE_CLIENT_PASSWORD"]
  config.debug = true # show Exchange request/response info
end
