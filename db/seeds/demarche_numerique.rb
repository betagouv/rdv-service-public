application = OauthApplication.new(
  name: "Démarche Numérique",
  uid: "oE-BQa9tyxXcwqmyT5wCuXymbNCfwIlLSFMmWfv6XO8",
  redirect_uri: "http://localhost:3002/auth/rdvservicepublic/callback\nhttp://127.0.0.1:3002/auth/rdvservicepublic/callback",
  post_logout_redirect_uri: "http://localhost:3002/",
  logo_base64: "",
  grants_autonomous_signup: true
)

test_secret = "development-A39QXp76ICRMmYqn_STrwsiLXYdkj2u4CtF9R8IgwnA" # Pour le développement en local uniquement
application.secret_strategy.store_secret(application, :secret, test_secret)
application.save!
