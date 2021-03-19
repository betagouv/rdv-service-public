Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV["CORS_ALLOWED_ORIGINS"]
    resource "*", headers: :any, methods: [:get, :post, :patch, :put], expose: ["client", "uid", "access-token"]
  end
end
