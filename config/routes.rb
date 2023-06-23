Rails.application.routes.draw do
  resources :packages
  resources :repositories
  resources :github_orgs
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  get '/healthz', to: proc { [200, {}, ['']] }
end
