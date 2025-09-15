Rails.application.routes.draw do
  get :health, to: "health_checks#index"

  post "/auth/login", to: "auth#login"
  get "/auth/me", to: "auth#me"

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

    namespace :payroll do
      get "me/daily_quote", to: "daily_quotes#me"
      get "user/daily_quote", to: "daily_quotes#user"
      get "daily_total", to: "daily_totals#show"
    end

    get "sales", to: "sales#show"
    put "sales", to: "sales#upsert"

    get "food_costs", to: "food_costs#show"
    put "food_costs", to: "food_costs#upsert"

    get "l_ratio/daily", to: "l_ratio#daily"
    get "l_ratio/monthly", to: "l_ratio#monthly"

    get "f_ratio/daily", to: "f_ratio#daily"
    get "f_ratio/monthly", to: "f_ratio#monthly"

    get "f_l_ratio/daily", to: "f_l_ratio#daily"
    get "f_l_ratio/monthly", to: "f_l_ratio#monthly"
  end
end
