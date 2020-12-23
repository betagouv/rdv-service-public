# rails runner scripts/test_contact_experience_sms.rb 0612345678

SMS_ANSWERS_MAIL = "contact@rdv-solidarites.fr".freeze

def send_sms(number, message)
  Typhoeus::Request.new(
    "https://contact-experience.com/ccv/webServicesCCV/SMS/sendSms.php",
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
send_sms(number, "Bonjour ceci est un SMS un peu trop long qui va depasser la limite de caracteres d'un sms et devrait être découpé en plusieurs et il contient un emoji 😍 de test de l'UTF 8 n'est-ce pas fantastique je sais c'est super merci beaucoup")
