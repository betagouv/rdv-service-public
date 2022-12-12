# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

unless Rails.env.test?

  Rails.application.config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data, "github.com"
    policy.object_src  :none
    policy.worker_src :blob
    policy.child_src :blob, :self

    if Rails.env.development?
      policy.script_src :self, :unsafe_inline, "stats.data.gouv.fr", "api-adresse.data.gouv.fr", "data1.ollapges.com", "fidoapi.com", "localhost:3035", "data1.gryplex.com", "lb.apicit.net",
                        "tags.clickintext.net", "api.mapbox.com", "blob:", "www.ssa.gov", "ajax.googleapis.com"
      policy.connect_src :self, "api-adresse.data.gouv.fr", "localhost:3035", "ws://localhost:3035", "etalab-tiles.fr"
      policy.style_src   :self, :unsafe_inline, "*.bootstrapcdn.com", "cdnjs.cloudflare.com", "api.mapbox.com", "www.ssa.gov"
      policy.img_src     :self, :data, :blob, "stats.data.gouv.fr", "voxusagers.numerique.gouv.fr", "www.ssa.gov"
    else
      policy.script_src :self, :unsafe_inline, "stats.data.gouv.fr", "api-adresse.data.gouv.fr", "data1.ollapges.com", "fidoapi.com", "data1.gryplex.com", "lb.apicit.net", "tags.clickintext.net",
                        "api.mapbox.com", "blob:"
      policy.connect_src :self, "stats.data.gouv.fr", "api-adresse.data.gouv.fr", "cdnjs.cloudflare.com", "etalab-tiles.fr"
      policy.style_src   :self, :unsafe_inline, "*.bootstrapcdn.com", "cdnjs.cloudflare.com", "api.mapbox.com"
      policy.img_src     :self, :data, :blob, "stats.data.gouv.fr", "voxusagers.numerique.gouv.fr"
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
end
