# scripts/test_contact_experience_sms.rb 0612345678

SMS_ANSWERS_MAIL = "contact@rdv-solidarites.fr".freeze

def send_sms(number, message)
  Typhoeus::Request.new(
    "https://contact-experience.fr/ccv/webServicesCCV/SMS/sendSms.php",
    params: {
      number: number,
      msg: message,
      devCode: ENV["CONTACT_EXPERIENCE_API_CODE"],
      emetteur: SMS_ANSWERS_MAIL
    }
  ).run
end

number = ARGV[0]
puts "phone number is #{number}"
send_sms(number, "Bonjour")
