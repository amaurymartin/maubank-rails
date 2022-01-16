Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  defaults format: :json do
    get '/health', to: ->(env) { [204, {}, ['']] }

    resources :sessions, only: :create
    resources :users, param: :key, except: :index
    resources :wallets, param: :key, except: :show
    resources :goals, param: :key
    resources :categories, param: :key
  end
end
