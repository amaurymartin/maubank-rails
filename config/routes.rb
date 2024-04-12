Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  defaults format: :json do
    resources :sessions, only: :create
    resources :users, param: :key, except: :index
    resources :wallets, param: :key, except: :show do
      resources :payments, only: %i[create index], module: :wallets
    end
    resources :goals, param: :key
    resources :categories, param: :key, shallow: true do
      resources :budgets, param: :key, except: :index
    end
    resources :payments, param: :key, except: :create
  end
end
