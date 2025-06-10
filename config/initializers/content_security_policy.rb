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
# Bouton "Je donne mon avis sur cette démarche"
voxusagers = "voxusagers.numerique.gouv.fr"
# Utilisé sur nos pages statiques (404.html, 500.html)
bootstrap_cdn = "*.bootstrapcdn.com"
# Headway nous permet de publier un changelog au sein de l'app
headway_cnd = "cdn.headwayapp.co"
headway_widget = "headway-widget.net"
# Metabase permet d’embedder des rapports dans l’application
metabase = "rdv-service-public-metabase.osc-secnum-fr1.scalingo.io"

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
  policy.frame_src :self, in_status, headway_widget, metabase
  policy.img_src :self, :data, :blob, voxusagers, tiles_osm, unpkg_cdn, tiles_data_gouv
  policy.style_src :self, :unsafe_inline, bootstrap_cdn, headway_cnd, unpkg_cdn
  policy.connect_src :self, api_adresse_ign, tiles_etalab, tiles_data_gouv

  # La source `unsafe_inline` autorise l'utilisation de js dans un tag `script` dans la page.
  # Idéalement, on voudrait donc la supprimer, puisque ça ajouterait une couche de protection contre les injections de JS.
  # On s'en sert pour deux choses:
  # - un script de customisation de headway qui est inliné : on pourrait ajouter une source de type sha pour éviter ça
  # - les mises à jour de statuts de rdvs qui utilisent des forms `js: true` et une view en `js.erb`. Si on pouvait éviter ce fonctionnement
  # (peut-être en utilisant des turbo-frames), on pourrait s'éviter l'usage de cette source ici.
  #
  # Il semble aussi que dans les tests capybara en js: true, un petit script est injecté pour lequel il faut aussi ajouter une source de type sha.
  #
  # Les sources de type sha permettent de s'assurer que seul le script correspondant exactement au sha peut-être chargé.
  # Cependant, elles ne sont pas prises en compte si la source 'unsafe_inline' est présente
  policy.script_src :self, :unsafe_inline, headway_cnd, unpkg_cdn
end

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }

# Set the nonce only to specific directives
# Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
