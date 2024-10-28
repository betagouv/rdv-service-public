# Ce middleware a été introduit pour observer les cas de CookieOverflow
# suite à la décision de repasser aux cookies comme stockage de session
# plutôt que Redis: https://github.com/betagouv/rdv-service-public/pull/4003
class CookieOverflowNotifyMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue ActionDispatch::Cookies::CookieOverflow => e
    Sentry.configure_scope do |scope|
      scope.set_context("path", { original_fullpath: env["ORIGINAL_FULLPATH"] })
      Sentry.capture_exception(e)
    end
    raise
  end
end

Rails.configuration.middleware.insert_before ActionDispatch::Session::CookieStore, CookieOverflowNotifyMiddleware
