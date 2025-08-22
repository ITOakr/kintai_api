Rails.application.routes.draw do
  get :health, to: "health_checks#index"

  scope :v1 do
    namespace :timeclock do
      resources :time_entries, only: [ :index, :create ]
    end
  end
end
