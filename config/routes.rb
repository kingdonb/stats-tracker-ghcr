Rails.application.routes.draw do
  devise_for :users, :controllers => {:registrations => "registrations", :omniauth_callbacks => "callbacks"}
  devise_scope :user do
    get 'login', to: 'devise/sessions#new'
  end
  devise_scope :user do
    get 'signup', to: 'devise/registrations#new'
  end

  get 'cookies/accept'
  resources :landings
  resources :packages
  resources :repositories
  resources :github_orgs
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get '/healthz', to: proc { [200, {}, ['']] }

  # Defines the root path route ("/")
  root "landings#index"
end
