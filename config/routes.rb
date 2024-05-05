Litestream::Engine.routes.draw do
  get "/" => "processes#show", :as => :root

  resource :process, only: [:show], path: ""
  resources :restorations, only: [:create]
end
