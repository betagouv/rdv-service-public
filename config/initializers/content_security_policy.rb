# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

# InStatus est le service dont on se sert pour communiquer les incidents
in_status = "*.instatus.com"
# Nous faisons des appels vers cette API dans notre recherche par adresse
api_adresse_ign = "data.geopf.fr"
# Nous utilisons mapbox via unpkg et les tiles etalab pour les interfaces de config de sectorisation
tiles_etalab = "etalab-tiles.fr"
# Nous utilisons unpkg, les tiles OSM et etalab pour afficher une carte des lieux dans les stats avec maplibre
unpkg_cdn = "unpkg.com"
tiles_osm = "tile.openstreetmap.org"
tiles_data_gouv = "openmaptiles.data.gouv.fr"
# Utilisé sur nos pages statiques (404.html, 500.html)
bootstrap_cdn = "*.bootstrapcdn.com"
# Metabase permet d’embedder des rapports dans l’application
metabase = "rdv-service-public-metabase.osc-secnum-fr1.scalingo.io"

# Utilisés par swagger pour la documentation de l'api
swagger_shas = ["'sha256-j4Lx1FqFgvYDBEjW7NQaEY7/HhCi8WVsLWkqC4+wJ3w='", "'sha256-JHKToH7KbGJj6TloPeWnKnbImDel00Whl1rRnBiTYuQ='"]

# Utilisé par Axios pour les tests d'accessibilité
test_shas = []
if Rails.env.test?
  test_shas << if ENV["CI"].present?
                 "'sha256-4UywW1I9VFu7o60u4zSiU9FmUjIhiIv4N1FflQjVse0='"
               else
                 "'sha256-MW9ENekiBxLmssEGlk+IVYZiQXOqQCOggVxAMOB1ePc='"
               end
end

# Tant qu'on utilise les Turbolinks, c'est très difficile d'avoir des CSP différentes pour chaque pages,
# puisque les CSP sont uniquement chargées lors de la première requête qui charle le premier document,
# et pas lors des appels XHR fait par les turbolinks.
#
# Si on voulait par exemple avoir une CSP uniquement pour les pages de la sectorisation qui affichent des cartes
# en JS, il faudrait donc s'assurer que tous les liens vers ces pages ont un attribut "data-turbolinks: false".
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src :self, :data # :data est nécessaire pour charger les icônes fullcalendar
  policy.object_src :none
  policy.worker_src :blob
  policy.child_src :blob, :self
  policy.frame_src :self, in_status, metabase
  policy.img_src :self, :data, :blob, tiles_osm, unpkg_cdn, tiles_data_gouv
  policy.style_src :self, :unsafe_inline, bootstrap_cdn, unpkg_cdn
  policy.connect_src :self, api_adresse_ign, tiles_etalab, tiles_data_gouv

  policy.script_src :self, unpkg_cdn, *swagger_shas, *test_shas
end

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }

# Set the nonce only to specific directives
# Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
