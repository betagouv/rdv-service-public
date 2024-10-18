# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

# InStatus est le service dont on se sert pour communiquer les incidents
in_status = "*.instatus.com"
# Nous hébergeons la vidéo de la page d'accueil de RDV_MAIRIE sur le s3 de RDV-Insertion
s3_de_rdv_insertion = "rdv-insertion-medias-production.s3.fr-par.scw.cloud"
# Nous faisons des appels vers cette API dans notre recherche par adresse
api_adresse_data_gouv = "api-adresse.data.gouv.fr"
# Nous utilisons mapbox et les tiles etalab pour les interfaces de config de sectorisation
api_mapbox = "api.mapbox.com"
tiles_etalab = "etalab-tiles.fr"
# Bouton "Je donne mon avis sur cette démarche"
voxusagers = "voxusagers.numerique.gouv.fr"
# Utilisé sur nos pages statiques (404.html, 500.html)
bootstrap_cdn = "*.bootstrapcdn.com"
# Headway nous permet de publier un changelog au sein de l'app
headway_cnd = "cdn.headwayapp.co"
headway_widget = "headway-widget.net"

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src :self, :data # :data est nécessaire pour charger les icônes fullcalendar
  policy.object_src :none
  policy.worker_src :blob
  policy.child_src :blob, :self
  policy.frame_src :self, in_status, headway_widget
  policy.media_src :self, s3_de_rdv_insertion
  policy.img_src :self, :data, voxusagers
  policy.style_src :self, :unsafe_inline, bootstrap_cdn, api_mapbox, headway_cnd
  policy.connect_src :self, api_adresse_data_gouv, tiles_etalab
  policy.script_src :self, :unsafe_inline, api_mapbox, headway_cnd

  if ENV["CI"].present?
    # Autorise à télécharger le binaire chromedriver pour l'exécution de la CI
    policy.script_src(*(policy.script_src + ["ajax.googleapis.com"]))
  end
end

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }

# Set the nonce only to specific directives
# Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
