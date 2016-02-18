Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'
  root 'obs_chgs#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  resources :pwr_data

  resources :load_descs

  resources :raw_data_files

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

  resources :obs_chgs do
    member do
      get 'backmatch'
      get 'endrun'
      get 'shot'
    end

    collection do
      get 'csvout'
      get 'wattvar'
      get 'range'
    end
  end

 # :member => { :backmatch => :get, :endrun => :get },
 #                :collection => { :csvout => :get, :wattvar => :get }

  resources :chg_sigs do
    member do
      get 'resetruns'
    end
  end

# , :member => { :resetruns => :get }

  resources :runs do
    member do
      get 'fwdmatch'
      get 'add_chg'
    end

    collection do
      get 'close'
    end
  end

# , :member => { :fwdmatch => :get, :add_chg => :get },
#                 :collection => { :close => :get }


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
