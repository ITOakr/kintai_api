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

    namespace :payroll do
      get "me/daily_quote", to: "daily_quotes#me"
      get "user/daily_quote", to: "daily_quotes#user"
      get "daily_total", to: "daily_totals#show"
    end

    get "sales", to: "sales#show"
    put "sales", to: "sales#upsert"

    get "l_ratio/daily", to: "l_ratio#daily"
  end
end
