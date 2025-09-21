Rails.application.routes.draw do
  get :health, to: "health_checks#index"

  post "/auth/login", to: "auth#login"
  get "/auth/me", to: "auth#me"

  resources :users, only: [ :index, :update, :destroy ]

  post "/users/signup", to: "users#signup"
  get "/users/pending", to: "users#pending"
  patch "/users/:id/approve", to: "users#approve"

  scope :v1 do
    namespace :timeclock do
      resources :time_entries, only: [ :index, :create ]
    end

    namespace :attendance do
      get "my/daily", to: "daily#show"
      get "me/daily", to: "daily#me"
    end

    get "sales", to: "sales#show"
    put "sales", to: "sales#upsert"

    get "food_costs", to: "food_costs#show"
    put "food_costs", to: "food_costs#upsert"

    get "daily_summary", to: "daily_summary#show"
    get "monthly_summary", to: "monthly_summary#show"

    resources :admin_logs, only: [ :index ]
  end
end
