# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

# Rails.application.config.middleware.insert_before 0, Rack::Cors do
#   allow do
#     origins "example.com"
#
#     resource "*",
#       headers: :any,
#       methods: [:get, :post, :put, :patch, :delete, :options, :head]
#   end
# end
origins = [
  "http://localhost:5173",          # Vite dev
  "https://flan-for-employee.vercel.app", # 後で実際のVercel URLに置換
  "https://flan-for-admin.vercel.app"     # すでに作るつもりなら先行でOK
]

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins origins
    resource "*",
      headers: :any,
      methods: [ :get, :post, :patch, :put, :delete, :options ],
      expose: [ "Authorization" ],
      max_age: 600
  end
end
