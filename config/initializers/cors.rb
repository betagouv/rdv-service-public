Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*"
    resource "/api/v1/*", headers: :any, methods: [:get, :post, :patch, :put], expose: ["client", "uid", "access-token"]
  end
end
