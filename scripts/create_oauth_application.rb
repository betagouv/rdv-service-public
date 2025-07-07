# Exemple:
# rails runner scripts/create_oauth_application.rb "RDV Insertion" "http://localhost:8000/auth/rdvsolidarites/callback"

application = Doorkeeper::Application.create!(
  name: ARGV[0],
  redirect_uri: ARGV[1],
  logo_base64: ""
)

puts "L'id de l'application est:"
puts application.uid

puts "Le secret de l'application est :"
puts application.plaintext_secret

puts "\rEnregistrez-le tout de suite dans un système sécurisé car il ne sera plus consultable."
puts "Vous pouvez ajouter un logo à l'application via la colonne logo_base64 (il faut un logo carré)."
