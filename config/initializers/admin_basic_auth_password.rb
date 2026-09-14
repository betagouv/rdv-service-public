# garde fou 1 : IS_REVIEW_APP ne peut être présent que si le nom de domaine contient bien review-app
# évite qu'on le définisse par erreur en demo / prod / staging
# schéma des HOST rdv-service-public-review-app-pr<N> (cf. scripts/devtools/create_review_app.rb)
if Rails.env.production? && ENV["IS_REVIEW_APP"] == "true" && ENV["HOST"].to_s.exclude?("review-app")
  raise "IS_REVIEW_APP vaut true mais HOST (#{ENV['HOST'].inspect}) ne correspond pas à une review app."
end

# garde fou 2 : ADMIN_BASIC_AUTH_PASSWORD ne peut être défini que sur les review apps uniquement
# Sa présence remplace l'authentification super-admin via ProConnect (en local on utilise ProConnect sandbox)
if Rails.env.production? && ENV["IS_REVIEW_APP"] != "true" && ENV["ADMIN_BASIC_AUTH_PASSWORD"].present?
  raise "ADMIN_BASIC_AUTH_PASSWORD ne doit jamais être définie en dehors des review apps"
end
