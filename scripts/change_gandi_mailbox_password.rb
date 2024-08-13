require "uri"
require "net/http"
require "active_support/all"
require "dotenv/load"
require "json"
require "securerandom"
Dotenv.load

email = ARGV[0]

if email.blank?
  puts "missing email argument"
  puts "Usage: change_gandi_mailbox.rb [options]"
  exit 1
end

puts "will change password for #{email}..."

api_key = ENV["GANDI_API_KEY"]
raise "variable d’environnement GANDI_API_KEY manquante, veuillez la rajouter à votre fichier .env" if api_key.blank?

domain = email.split("@")[1]

def perform_request(request)
  http = Net::HTTP.new("api.gandi.net", "443")
  http.use_ssl = true
  request["authorization"] = "Bearer #{ENV['GANDI_API_KEY']}"
  request["content-type"] = "application/json"
  http.request(request)
end

response = perform_request(Net::HTTP::Get.new("/v5/email/mailboxes/#{domain}"))
raise "error while fetching mailboxes: #{response.body}" unless response.code == "200"

mailbox_id = JSON.parse(response.body).find { _1["address"] == email }&.fetch("id", nil)
raise "mailbox #{email} not found" if mailbox_id.blank?

puts "mailbox_id found #{mailbox_id}"

def generate_secure_password
  special_characters = "!@#$%^&*()_+[]{}|;:,.<>?/~`"
  password = ""

  loop do
    password = SecureRandom.base64(rand(30..40)) # Generate a base64 string of random length
    password += SecureRandom.random_number(10).to_s * 3 # Ensure at least 3 numbers
    password += SecureRandom.base64(1).upcase # Ensure at least 1 upper-case letter
    password += special_characters.chars.sample # Ensure at least 1 special character

    # Shuffle the password to mix the characters
    password = password.chars.shuffle.join

    # Check if the password meets the length requirement
    break if password.length.between?(30, 200)
  end

  password
end

password = generate_secure_password

request = Net::HTTP::Patch.new("/v5/email/mailboxes/#{domain}/#{mailbox_id}")
request.body = JSON.dump({ password: })
puts "trying to set new password #{password}"

response = perform_request(request)
raise "error while changing password: status #{response.code} - body : #{response.body}" unless response.code == "202"

puts "new password set for #{email} (#{password.size * 8} bits)\n-----#{password}\n------\n"
