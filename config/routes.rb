Rails.application.routes.draw do
  require 'resque_web'

  resque_web_constraint = ->(request) do
    current_user = request.env['warden'].user
    current_user.present? && current_user.admin?
  end

  constraints resque_web_constraint do
    mount ResqueWeb::Engine => '/resque_web'
  end

  require 'sidekiq/web'
  require 'sidekiq-scheduler/web'
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  tolk_constraint = ->(request) do
    current_user = request.env['warden'].user
    current_user.present? && (current_user.admin? || current_user.translator?)
  end

  constraints tolk_constraint do
    mount Tolk::Engine => '/tolk', as: 'tolk'
  end

  constraints CanAccessFlipperUI do
    mount Flipper::UI.app(Flipper) => '/flipper', as: 'flipper'
  end

  mount ActionCable.server => '/cable'

  devise_for :users,
             skip: [
               :sessions,
               :registrations
             ],
             controllers: {
               registrations: 'users/registrations',
               sessions:      'users/sessions',
               passwords:     'users/passwords',
               unlocks:       'users/unlocks'
             }

  devise_scope :user do
    get    'sign-in',              to: 'users/sessions#new',                       as: :new_user_session
    post   'sign-in',              to: 'users/sessions#create',                    as: :user_session
    delete 'sign-out',             to: 'users/sessions#destroy',                   as: :destroy_user_session

    get    'sign-in-with-shopify', to: 'users/sessions#sign_in_with_shopify',      as: :sign_in_with_shopify
    get    'cannot-sign-in',       to: 'users/sessions#problems',                  as: :sign_in_problems

    get    'sign-up',              to: "devise/registrations#new",                 as: :new_user_registration
    post   'sign-up',              to: "devise/registrations#create",              as: :user_registration

    delete 'users',                to: "users/registrations#destroy"

    get    'sign-up-with-shopify', to: 'users/registrations#sign_up_with_shopify', as: :sign_up_with_shopify

    unauthenticated :user do
      root 'users/sessions#new'
    end

    authenticated :user do
      root 'back/dashboard#index'
    end
  end

  get '/auth/:provider/callback', to: 'oauth/callbacks#success'
  get '/auth/failure',            to: 'oauth/callbacks#failure'

  namespace :oauth do
    resources :ecwid_sessions, only: [:new] do
      collection do
        get :success
      end
    end
    resources :shopify_sessions, only: [:new] do
      collection do
        get :success
      end
    end
  end

  namespace :resources, path: '/res' do
    resources :ecwid, only: [:index, :storefront_scripts] do
      get :index,              on: :collection, path: '/:store_id'
      get :storefront_scripts, on: :collection
    end
    resources :lemonstand, only: [:index, :storefront_scripts] do
      get :storefront_scripts, on: :collection, path: 'scripts/:store_id'
      get :index,              on: :collection, path: '/:store_id'
    end
    resources :widgets,    only: [:index], path: 'widgets/:store_id'
    resources :cloudinary, only: [:signature, :styles] do
      get :signature, on: :collection
      get :styles,    on: :collection
    end
  end
  get '/integrations-ecwid',      to: 'resources/ecwid#storefront_scripts'

  namespace :callbacks do
    resource :ecwid,    only: [:create], controller: :ecwid
    resource :shopify,  only: [:create], controller: :shopify do
      post :create, on: :collection, path: '/:object/(:event)'
    end
    resource :lemonstand,  only: [:create], controller: :lemonstand do
      post :create, on: :collection, path: '/:event'
    end

    post 'chargebee', to: 'chargebee#create'

    post 'facebook/reviews_tab', to: 'facebook#reviews_tab'
  end

  namespace :back, path: '/cp' do
    root 'dashboard#index', as: :root

    resources :dashboard, only: [:index] do
      collection do
        get :index
        get :product_stats
      end
    end

    resources :stores, only: [:create] do
      collection do
        get :connect_store,               as: 'connect'
        get :connect_with_custom_website, to: 'stores#connect_with_custom_website'
        get :connect_with_ecwid,          to: 'stores#connect_with_ecwid'
        get :connect_with_lemonstand,     to: 'stores#connect_with_lemonstand'
        get :reconnect_with_lemonstand,   to: 'stores#reconnect_with_lemonstand'
        get :connect_with_shopify,        to: 'stores#connect_with_shopify'
      end
    end

    put '/settings/store', to: 'stores#update', as: :store

    resource :lemonstand_setup, only: [:create, :update], controller: :lemonstand_setup

    resources :review_requests, path: '/reviews/requests' do
      post :cancel,   on: :member
      post :send_now, on: :member

      post :process_on_hold, on: :collection

      collection do
        resources :bulk_request, only: [:create], module: :review_requests, as: :bulk_request do
          get :new, path: '', on: :collection
        end
      end
    end

    get   :index,  controller: :reviews, as: :reviews, path: '/reviews/moderation'
    get   :show,   controller: :reviews, as: :review,  path: '/reviews/moderation/:id'
    put   :update, controller: :reviews,               path: '/reviews/moderation/:id'
    patch :update, controller: :reviews,               path: '/reviews/moderation/:id'

    resources :reviews, only: [] do
      post :publish_all_pending, on: :collection

      resources :comments,     only: [:create, :update], module: :reviews
      resources :social_posts, only: [:create],          module: :reviews
      resources :media,        only: [:update],          module: :reviews

      collection do
        get   '/emails',           controller: 'reviews/settings', action: 'email_templates',         as: :emails
        patch '/emails',           controller: 'reviews/settings', action: 'update_email_templates',  as: :update_emails
        post  '/send_test_email/:email_type',  controller: 'reviews/settings', action: 'send_test_email',  as: :send_test_email

        get   '/social_templates', controller: 'reviews/settings', action: 'social_templates',        as: :social_templates
        patch '/social_templates', controller: 'reviews/settings', action: 'update_social_templates', as: :update_social_templates

        # TODO OPTIMIZE
        patch '/hide_reviews_check_announcement', controller: 'reviews/settings', action: 'hide_check_announcement', as: :hide_reviews_check_announcement
      end
    end

    resources :imported_reviews, only: [:index, :update], path: '/tools/data_import/reviews' do
      post :proceed, on: :collection
    end

    resources :imported_review_requests, only: [:index, :update], path: '/tools/data_import/requests' do
      post :proceed, on: :collection
    end

    resources :imported_questions, only: [:index, :update], path: '/tools/data_import/q-a' do
      post :proceed, on: :collection
    end

    get :index,  controller: :questions, as: :questions, path: '/q-a/moderation'
    get :show,   controller: :questions, as: :question,  path: '/q-a/moderation/:id'
    put :update, controller: :questions,                 path: '/q-a/moderation/:id'

    resources :questions, only: [], path: '/q-a/' do
      resources :comments,     only: [:create, :update], module: :questions
      resources :social_posts, only: [:create],          module: :questions

      collection do
        get   '/emails',           controller: 'questions/settings', action: 'email_templates',         as: :emails
        patch '/emails',           controller: 'questions/settings', action: 'update_email_templates',  as: :update_emails

        get   '/social_templates', controller: 'questions/settings', action: 'social_templates',        as: :social_templates
        patch '/social_templates', controller: 'questions/settings', action: 'update_social_templates', as: :update_social_templates

        # TODO OPTIMIZE
        patch '/hide_questions_check_announcement', controller: 'questions/settings', action: 'hide_check_announcement', as: :hide_questions_check_announcement
      end
    end

    resources :comments, only: [:edit, :destroy]

    resources :products, path: 'products/catalog' do
      collection do
        resource :upload, only: [:create], module: :products, controller: 'upload', as: :products_upload do
          get :new, path: '', on: :collection
        end

        post :sync
      end
    end

    resources :product_groups, path: 'products/groups'

    resources :customers, only: [:show]

    resources :social_accounts, only: [:destroy]

    resources :users, only: [:edit, :update]

    resources :bundles, only: [:new, :show, :create, :update] do
      post :preview, on: :new
    end

    resources :subscriptions, only: [:create, :destroy] do
      post :abort
    end

    resources :shopify_payments, only: [:new] do
      get :confirm, on: :collection
    end

    resource :chargebee_payments, only: [] do
      post :confirm, on: :collection
      post :portal, on: :collection
    end

    resources :downloads, only: [:show]

    resources :tools, only: '' do
      collection do
        get   :seed,       path: 'data_import'
        get   :onboarding, path: 'setup_guide'
        get   :downloads,  path: 'downloads'
        get   :widget_console,  path: 'widget_console'

        post  :seed_orders
        post  :seed_questions_csv
        post  :seed_reviews_csv

        put   :update
        patch :update
      end
    end

    resources :settings, only: '' do
      collection do
        get   :design
        get   :onboarding,      path: 'setup_guide'
        get   :features
        get   :social_accounts
        get   :promotions
        get   :general
        get   :widgets
        get   :billing

        post  :select_facebook_page

        put   :update
        patch :update
      end
    end

    resources :promotions, path: '/tools/promotions'

    # TODO OPTIMIZE
    patch '/hide_promotions_check_announcement', controller: 'promotions', action: 'hide_check_announcement', as: :hide_promotions_check_announcement

    resources :discount_coupons, only: [:index, :new, :create, :show, :edit, :update, :destroy], path: '/tools/discount_coupons' do

      resources :coupon_codes, only: [:index, :destroy], module: :discount_coupons

      collection do
        get  :import
        post :sync
        get  :history
      end

      member do
        get :template
      end
    end
    resources :suppressions,  only: [:index, :new, :create, :destroy],       path: '/tools/email_suppressions'
    resources :abuse_reports, only: [:index, :new, :create, :show, :update], path: '/tools/contentguard' do
      collection do
        get :filters
      end
    end
  end

  namespace :front, path: '/f/:store_id' do
    resources :reviews,   only: [:index]
    resources :questions, only: [:index], path: '/q-a'

    resources :review_requests, path: '/requests' do
      resources :reviews, only: [:new], path_names: { new: 'new(/:transaction_item_id)' }, module: :review_requests do
        collection do
          post  :create
          put   :create
          patch :create
        end
      end
    end

    resources :suppressions, only: [:create, :destroy, :index, :show] do
      get :manage_subscriptions, on: :collection
    end

    resources :products, only: [:show] do
      resources :reviews, only: [:index, :show, :new, :create], module: :products do
        resources :votes,     only: [:create],   module: :reviews
        resources :flags,     only: [:create],   module: :reviews
      end

      resources :questions, only: [:index, :show, :new, :create], module: :products do
        resources :flags, only: [:create], module: :questions
        resources :votes, only: [:create], module: :questions
      end
    end

    resources :widgets, only: [], path: '/w' do
      collection do
        get :sidebar
        get :review_slider
        get :review_journal
        get :reviews_facebook_tab

        resources :products, only: [] do #module: :widgets
          get :tabs,    controller: 'widgets/products'
          get :rating,  controller: 'widgets/products'
          get :summary, controller: 'widgets/products'
          get :ld_json, controller: 'widgets/products'
        end
      end
    end

    resources :plugins, only: [] do
      get :display_name, on: :collection
    end
  end

  namespace :integrations do
    namespace :ecwid do
      root      'dashboard#index'
      resources :dashboard, only: [:index]
    end

    namespace :shopify do
      root      'dashboard#index'
      resources :dashboard,  only: [:index]
      resource  :onboarding, only: '', controller: 'onboarding' do # TODO controller should not be necessary
        collection do
          post :auto_injection
          post :auto_remove
          post :check_embed_success
        end
      end
    end
  end

  get :widgets, controller: 'integrations/static', path: '/f/:store_id/widgets/(:widget)', as: :integrations_widgets

  namespace :api, path: '/api' do
    resources :email_events, except: [ :index ]
  end

  namespace :admin do
    root 'dashboards#index'

    resources :dashboards, only: '' do
      collection do
        get :authentication_stats
        get :billing
        get :reporting
        get :problematic_stores
        get :feature_usage
        get :index
        get :icon_test_svg
        get :icon_test_font
      end
    end

    resources :reviews,       only: [:index, :show], path: 'hc_reviews' # TODO: path with 'hc_' should not be necessary but it goes to front/reviews controller otherwise.. TODO qa as well
    resources :questions,     only: [:index, :show], path: 'hc_qa'
    resources :abuse_reports, only: [:index, :show], path: 'contentguard'

    resources :stores, only: [ :index, :show, :update ] do
      member do
        get   :settings
        patch :update_settings
        post  :sync_products
        post  :sync_shopify
        post  :check_widgets
        post :withhold
        post :release_hold
        post :extend_trial
        post :delete_data
        post :delete_imported_reviews
        post :anonymize
        post :grant_orders
        post :grant_products
        post :export_products
        post :change_pricing_model
        post 'translator_permissions' => 'stores#grant_translator_permissions'
        delete 'translator_permissions' => 'stores#remove_translator_permissions'
      end

      resources :downloads, only: [:index, :destroy], controller: 'stores/downloads' do
        collection do
          post :export_reviews
          post :export_questions
        end
      end
    end

    resources :users, only: [ :index ] do
      post :impersonate,        on: :member
      post :stop_impersonating, on: :collection
      post :deactivate,         on: :member
      post :reactivate,         on: :member
    end

    resources :pricing, only: [:index] do
      collection do
        get :plans
        get :addons
        get :package_discounts
        get :coupons
      end
    end
    resources :addons, except: [:index, :destroy]
    resources :plans, except: [:index, :destroy]
    resources :package_discounts, except: [:index ]

    resources :reporting, only: [] do
      collection do
        post :export_stores_to_csv
        get :billing
        get :monthly_requests
        get :monthly_reviews
        get :monthly_questions
      end
    end
  end
end
