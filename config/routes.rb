Rails.application.routes.draw do
  resources :landings
  resources :packages
  resources :repositories
  resources :github_orgs
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get '/healthz', to: proc { [200, {}, ['']] }

  # Defines the root path route ("/")
  root "landings#index"
end
