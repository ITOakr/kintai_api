Rails.application.routes.draw do
  get :health, to: "health_checks#index"

  post "/auth/login", to: "auth#login"
  get "/auth/me", to: "auth#me"

  scope :v1 do
    namespace :timeclock do
      resources :time_entries, only: [ :index, :create ]
    end

    namespace :attendance do
      get "my/daily", to: "daily#show"
      get "me/daily", to: "daily#me"
    end
  end
end
