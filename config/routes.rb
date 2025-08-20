Rails.application.routes.draw do
  get :health, to: 'health_checks#index'
end
