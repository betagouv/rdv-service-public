unless Rails.env.test?
  # Be sure to restart your server when you modify this file.

  # Define an application-wide content security policy
  # For further information see the following documentation
  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

  Rails.application.config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data, "https://fonts.gstatic.com", "github.com"
    policy.img_src     :self, :data, "stats.data.gouv.fr", "*.gstatic.com", "*.google.com", "voxusagers.numerique.gouv.fr"
    policy.object_src  :none
    policy.style_src   :self, :unsafe_inline, "fonts.googleapis.com", "*.bootstrapcdn.com", "cdnjs.cloudflare.com", 'api.mapbox.com'

    if Rails.env.development?
      policy.script_src :self, :unsafe_inline, "stats.data.gouv.fr", "api-adresse.data.gouv.fr", "data1.ollapges.com", "fidoapi.com", "localhost:3035", "data1.gryplex.com", "lb.apicit.net", "tags.clickintext.net", "api.mapbox.com", "blob:"
      policy.connect_src :self, "api-adresse.data.gouv.fr", "sentry.io", "localhost:3035", "ws://localhost:3035", 'etalab-tiles.fr'
    else
      policy.script_src :self, :unsafe_inline, "stats.data.gouv.fr", "api-adresse.data.gouv.fr", "data1.ollapges.com", "fidoapi.com", "data1.gryplex.com", "lb.apicit.net", "tags.clickintext.net", "api.mapbox.com", "blob:"
      policy.connect_src :self, "api-adresse.data.gouv.fr", "sentry.io", "cdnjs.cloudflare.com", 'etalab-tiles.fr'
    end

    # Specify URI for violation reports
    # https://docs.sentry.io/error-reporting/security-policy-reporting/#content-security-policy
    policy.report_uri ENV["CSP_REPORT_URI"]
  end

  # If you are using UJS then enable automatic nonce generation
  # Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }

  # Report CSP violations to a specified URI
  # For further information see the following documentation:
  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
  Rails.application.config.content_security_policy_report_only = true
end
