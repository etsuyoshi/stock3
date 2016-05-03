Rails.application.routes.draw do

  # get 'study_pages/*path', to: 'study_pages#show'
  get 'study_pages/*path', to: 'study_pages#show'
  get 'study_pages/home'
  get 'study_pages/help'

  get 'password_resets/new'



  get 'password_resets/edit'

  root to: 'static_pages#home'
  # ニュースフィード(feed)取得用のコントローラ
  get 'fetch/index'
  match '/fetch',   to: 'fetch#index', via: 'get'
  get 'static_pages/home'
  get 'static_pages/nikkei'
  get 'static_pages/dow'
  get 'static_pages/shanghai'
  get 'static_pages/europe'
  get 'static_pages/bitcoin'
  get 'static_pages/commodity'
  get 'static_pages/adr'
  get 'static_pages/fx'
  get 'static_pages/portfolio'
  get 'static_pages/kessan'

  # http://stackoverflow.com/questions/15536123/rails-link-to-static-pages-issue
  get 'static_pages/detail_adr', :as => 'detail_adr'
# get "staticpages/faq", :as => 'faq_page'

  # get ':controller(/:action(/:id(.:format)))'
  get 'priceseries/new'
  get 'signup' => 'users#new'
  get 'rank/index'
  get 'adr/index'
  get 'price_newest/index'
  get 'login' => 'sessions#new'
  post 'login' => 'sessions#create'
  delete 'logout' => 'sessions#destroy'

  # get 'users/new'
  resources :users
  resources :account_activations, only: [:edit]
  resources :password_resets,     only: [:new, :create, :edit, :update]
  resources :posts

  #news feed専用ビュー
  #get 'feeds/show'
  resources :feeds
  resources :price_newest



  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
