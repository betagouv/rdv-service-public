# Un middleware rack pour afficher la page d'erreur statique si jamais une erreur est levée lors de l'appel à ErrorsController
class FallbackErrorMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    response = @app.call(env)

    if failsafe_response_from_default_middleware?(response)
      [500, { Rack::CONTENT_TYPE => "text/html; charset=utf-8" }, [Rails.public_path.join("maintenance.html").read]]
    else
      response
    end
  end

  private

  # Check if we're getting the Failsafe response from the Action Dispatch::ShowExceptions middleware
  def failsafe_response_from_default_middleware?(response)
    response.first == 500 && response.last.is_a?(Array) && response.last.first.include?("If you are the administrator of this website")
  end
end

Rails.configuration.middleware.insert_before(ActionDispatch::ShowExceptions, FallbackErrorMiddleware)
