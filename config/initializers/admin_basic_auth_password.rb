# Ce garde fou limite la possibilité de définir ADMIN_BASIC_AUTH_PASSWORD aux review apps uniquement
# Sa présence remplace l'authentification super-admin via ProConnect
# En local on utilise une sandbox ProConnect
if Rails.env.production? && ENV["IS_REVIEW_APP"] != "true" && ENV["ADMIN_BASIC_AUTH_PASSWORD"].present?
  raise "ADMIN_BASIC_AUTH_PASSWORD ne doit jamais être définie en dehors des review apps"
end
