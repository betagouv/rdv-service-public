# Un middleware rack pour afficher la page d'erreur si jamais une erreur est levée par le code Rails
# qui gère habituellement les erreurs
class FallbackErrorMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    response = @app.call(env)

    if response.first == 500 # && response.last.first.include?("If you are the administrator of this website") # Failsafe response from the Action Dispatch::ShowExceptions middleware
      [500, { Rack::CONTENT_TYPE => "text/html; charset=utf-8" }, [File.read(Rails.root.join("public/maintenance.html"))]]
    else
      response
    end
  end
end
