Spree::Core::Engine.add_routes do
  namespace :admin do
    resources :store_credits
    resources :users do
      resources :store_credits
    end
  end
end
