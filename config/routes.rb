Rails.application.routes.draw do
  resources :videos
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  mount Mux::Engine, at: "/mux" # provide a custom path

end
