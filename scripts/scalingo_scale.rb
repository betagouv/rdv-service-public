# ruby scripts/scalingo_scale.rb --name web --amount 2

require "optparse"
require "json"
require "typhoeus"
require "dotenv/load"

HEADERS = {
  "Accept" => "application/json",
  "Content-Type" => "application/json",
}.freeze

options = {}
OptionParser.new do |parser|
  parser.on("--app APP_NAME", "Application name (ie demo-rdv-solidarites)") do |val|
    options[:app_name] = val
  end

  parser.on("--containers-name NAME", "Container name (web, worker)") do |val|
    raise StandardError, "invalid container name, must be 'web' or 'worker'" \
      unless ["web", "worker"].include?(val)

    options[:containers_name] = val
  end

  parser.on("--containers-amount AMOUNT", "Number of containers, between 1 and 10") do |val|
    val_int = val.to_i
    raise StandardError, "invalid containers amount, must be between 1 and 10" unless val_int >= 1 && val_int <= 10

    options[:containers_amount] = val_int
  end
end.parse!

[:app_name, :containers_name, :containers_amount].each do |required_opt|
  raise StandardError, "missing option #{required_opt}" if options[required_opt].nil?
end

bearer_token = JSON.parse(
  Typhoeus.post(
    "https://auth.scalingo.com/v1/tokens/exchange",
    headers: HEADERS,
    userpwd: ":#{ENV['SCALINGO_API_TOKEN']}"
  ).body
)["token"]

res = JSON.parse(
  Typhoeus.post(
    "https://api.osc-secnum-fr1.scalingo.com/v1/apps/#{options[:app_name]}/scale",
    headers: HEADERS.merge({ "Authorization" => "Bearer #{bearer_token}" }),
    body: JSON.dump(
      containers: [
        {
          name: options[:containers_name],
          amount: options[:containers_amount]
        }
      ]
    )
  ).body
)
error_string = \
  if res["error"]
    res["error"]
  elsif res["errors"]
    res["errors"].map(&:to_a).map { _1.join(" ") }.join(", ")
  end
raise StandardError, error_string if error_string
