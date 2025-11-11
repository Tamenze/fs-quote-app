Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
     if ENV["ENABLE_SENTRY_TEST_ROUTES"] == "1"
      get "/ops/sentry_ping",  to: "ops#sentry_ping"
      get "/ops/sentry_boom",  to: "ops#sentry_boom" 
     end

    namespace :v1 do 
      resources :quotes do 
        collection do 
          get 'random', to: 'quotes#show_random'
        end 
      end 
      resources :tags 
      resources :users, only: [:show, :index, :update, :destroy]

      namespace :auth do 
        resource :csrf, only: :show
        post 'sign_up' => 'users#create'
        post 'login' => 'sessions#create'
        get 'me' => 'sessions#show'
        delete 'logout' => 'sessions#destroy'
      end 
    end 
  end 
end
