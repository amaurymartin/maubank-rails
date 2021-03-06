Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  defaults format: :json do
    get '/health', to: ->(env) { [204, {}, ['']] }

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
