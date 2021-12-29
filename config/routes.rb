Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  defaults format: :json do
    get '/health', to: ->(env) { [204, {}, ['']] }

    resources :users, param: :key, except: :index
  end
end
