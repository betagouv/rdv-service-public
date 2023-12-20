home_path = `echo $HOME`.squish

scalingo_auth = JSON.parse(File.read("#{home_path}/.config/scalingo/auth"))

scalingo_api_token = scalingo_auth.dig("auth_config_data", "auth.scalingo.com", "tokens", "token")

puts scalingo_api_token
