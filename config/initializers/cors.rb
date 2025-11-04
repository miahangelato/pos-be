# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Development origins
    development_origins = ["localhost:3000", "localhost:5173", "localhost:5174", "127.0.0.1"]
    
    # Production origins from environment variable
    production_origins = ENV['ALLOWED_ORIGINS']&.split(',') || []
    
    # Combine origins based on environment
    allowed_origins = Rails.env.production? ? production_origins : development_origins
    
    origins(*allowed_origins)

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
